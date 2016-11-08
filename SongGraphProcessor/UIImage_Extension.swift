//
//  UIImage_Extension.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-10-29.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import CoreText

extension UIImage
{
    // MARK: Constants.
    static let kFontName: String                           = "ringBearer"
    static let kFontSize: Int                              = 14
    
    static let kAlbumArtworkSize: Int                      = 63
    
    static let kGraphTopMargin: Int                        = 60
    static let kGraphBottomMargin: Int                     = 10
    static let kGraphMiddleMargin: Int                     = 30
    static let kWaveMaxHeight: Int                         = 50
    
    static let kTimeNumberLineThickness: Int               = 2
    static let kTimeNumberLineHeight: Int                  = 20
    
    static let kTimeNumberLineMinuteMarkThickness: Int     = 4
    static let kTimeNumberLineMinuteMarkHeight: Int        = 17
    
    static let kTimeNumberLineFiveSecondMarkThickness: Int = 2
    static let kTimeNumberLineFiveSecondMarkHeight: Int    = 13
    
    static let kTimeNumberLineOneSecondMarkThickness: Int  = 2
    static let kTimeNumberLineOneSecondMarkHeight: Int     = 8
    
    static let kTimeLineNumberLineTextMargin: Int          = 20
    static let kTimeLineNumberLineTextMarkerOffset: Int    = 15
    static let kTimeLineNumberLineTextMarkerMargin: Int    = 4
    
    static let kGraphMarkerBaseWidth: Int                  = 5
    static let kGraphMarkerBaseHeight: Int                 = 20
    static let kGraphStartMarkerWidth: Int                 = 3
    static let kGraphEndMarkerWidth: Int                   = 3
    
    static let kStepperDelta: Int                          = 1
    
    static let kNumberOfSecondsOffset: Int                 = 3
    static let kPracticeItemMissingName: Int               = 100
    static let kPracticeItemBadStartStop: Int              = 101
    static let kPracticeItemStopToLarge: Int               = 102
    static let kPracticeItemNotUnique: Int                 = 103
    
    static let kMusicPlayerIntervalTollerance: Double      = 0.17
    
    static let kSectionKey: String                   = "songHeader"
    static let kGraphColorBackground: UIColor        = UIColor.green
    static let kGraphColorLeftChannel: UIColor       = UIColor.blue
    static let kGraphColorRightChannel: UIColor      = UIColor.black
    static let kGraphColorTimeLine: UIColor          = UIColor.purple
    static let kGraphColorTimeNumberMarkers: UIColor = UIColor.gray
    static let kGraphColorTimeNumberLetters: UIColor = UIColor.orange
    
    static let kGraphColorMarkerBase: UIColor        = UIColor.black
    static let kGraphColorStartMarker: UIColor       = UIColor.red
    static let kGraphColorEndMarker: UIColor         = UIColor.red
    
    static let iPracticeErrorDomain: String          = "iPracticeErrorDomain"
}

extension UIImage
{
    class func getTimingInfo(fromSong: MPMediaItem, completion: @escaping (CMTime?, UIImageErrors?) -> Void ) -> Void
    {
        guard let audioCacheFile = BundleWrapper.getImportCacheFileURL(forSong: fromSong)
            else
        {
            completion(nil, UIImageErrors.importCacheFileNotFound(errorMessage: "In __FUNC__ and unable to obtain the location of the Import Audio Cache file!"))
            return
        }
        let assetOptions: [String : Any] = [AVURLAssetPreferPreciseDurationAndTimingKey : NSNumber(value: true)]
        let avAsset = AVURLAsset(url: audioCacheFile, options: assetOptions)
        
        // Properties of the AVURLAsset are not immediately available.
        // Therefore we load them asynchronously and then check on the status
        // of each of the properties that we need.
        avAsset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler:
            {
                var error: NSError?
                let status = avAsset.statusOfValue(forKey: "duration", error: &error)
                switch status
                {
                case .loaded:
                    completion(avAsset.duration, nil)
                case .cancelled, .failed, .loading, .unknown:
                    completion(nil, UIImageErrors.importCacheFileNotFound(errorMessage: "Tried to load the attribute [duration] in \(#function) and it failed with the error: \(error?.localizedDescription)"))
                }
        })
    }
    
    class func image(fromSong: MPMediaItem, graphMaxWidth: Int, graphMaxHeight: Int, completion: @escaping (UIImage?, UIImageErrors?) -> Void) -> Void
    {
        // Need to do a quick check to see whether we already have the Image or
        // what is known as the Song Graph File.
        guard let audioCacheFile = BundleWrapper.getImportCacheFileURL(forSong: fromSong)
            else
        {
            completion(nil, UIImageErrors.importCacheFileNotFound(errorMessage: "In \(#function) and unable to obtain the location of the Import Audio Cache file!"))
            return
        }
        let avAsset = AVURLAsset(url: audioCacheFile, options: nil)
        UIImage.getTimingInfo(fromSong: fromSong, completion:
            {
                (accurateDuration, imageError) in
                
                do
                {
                    if let imageError = imageError
                    {
                        completion(nil, imageError)
                        return
                    }
                    let bitDepth = 16
                    let reader: AVAssetReader = try AVAssetReader(asset: avAsset)
                    let songTrack: AVAssetTrack = avAsset.tracks[0]
                    let options: [String : Any] = [AVFormatIDKey               : kAudioFormatLinearPCM,
                                                   AVLinearPCMBitDepthKey      : bitDepth,
                                                   AVLinearPCMIsBigEndianKey   : false,
                                                   AVLinearPCMIsFloatKey       : false,
                                                   AVLinearPCMIsNonInterleaved : false
                    ]
                    let trackOutput = AVAssetReaderTrackOutput(track: songTrack, outputSettings: options)
                    trackOutput.alwaysCopiesSampleData = false
                    reader.add(trackOutput)
                    // AVLinearPCMBitDepthKey was set to 16 bits or 2 bytes.
                    var samplesPerSecond: UInt32 = 0
                    var channelCount: UInt32 = 0
                    let formats = songTrack.formatDescriptions
                    if formats.count > 1
                    {
                        print("Warning: There were more than one format in this song so the sampleRate & channelCount will reflect what was on the last format!")
                    }
                    var songLengthInSecs: TimeInterval = 0
                    let formatDescription = formats.last as! CMAudioFormatDescription
                    if let audioDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
                    {
                        samplesPerSecond = UInt32(audioDescription.pointee.mSampleRate)
                        if let hasAccurateDuration = accurateDuration
                        {
                            songLengthInSecs = Double(Double(hasAccurateDuration.value) / Double(hasAccurateDuration.timescale))
                        }
                        else
                        {
                            songLengthInSecs = fromSong.playbackDuration
                        }
                        channelCount = audioDescription.pointee.mChannelsPerFrame
                    }
                    // We have multiple channels.
                    var songMaxSignal: Int16 = 0
                    let fullSongData: NSMutableData = NSMutableData()
                    // Begin ..............
                    reader.startReading()
                    var totalBytes: UInt64 = 0
                    var totalLeft: Int64 = 0
                    var totalRight: Int64 = 0
                    var sampleTally: UInt = 0
                    // Very Important here to convert pixelsPerSecond & samplesPerPixel to Integer so drawing on the Image can be accurate.
                    // Basically this is: total width in pixels chosen for the graph / total seconds in the song.
                    let pixelsPerSecond: UInt = UInt(ceil(Double(graphMaxWidth)/songLengthInSecs))
                    // Basically this is: samples per second / pixels per second which becomes samples / second * second / pixel which cancels the seconds and leaves samples / pixel.
                    // Also notice that samplesPerPixel means that we roll up 'samplesPerPixel' samples and average them to be represented in one pixel.
                    let samplesPerPixel: UInt = UInt(ceil(Double(samplesPerSecond)/Double(pixelsPerSecond)))
                    while (reader.status == AVAssetReaderStatus.reading)
                    {
                        guard let sampleBuffer = trackOutput.copyNextSampleBuffer(), let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                            break
                        }
                        let length: Int = CMBlockBufferGetDataLength(blockBuffer)
                        totalBytes = totalBytes + UInt64(length)
                        
                        // Copy their data into our buffer.
                        var data = Data(capacity: length)
                        data.withUnsafeMutableBytes {
                            (bytes: UnsafeMutablePointer<Int16>)
                            
                            in
                            
                            CMBlockBufferCopyDataBytes(blockBuffer, 0, length, bytes)
                            let sampleArray = UnsafeMutablePointer<Int16>(bytes)
                            // We did this so we can divey it up into 16 bit chunks.
                            // Remember when we started the Reader Track Output we specified AVLinearPCMBitDepthKey = 16.
                            let iterativeSampleCount: Int = length / MemoryLayout<Int16>.size
                            // NOTE: Sample are both (-) & (+) and represent the y coordinate of the ups and downs of a sound wave.
                            var i: Int = 0
                            while i < (iterativeSampleCount - 1)
                            {
                                // Extract the Left Channel Sample.
                                // Seems that there may be an overflow here.
                                totalLeft = totalLeft + Int64(sampleArray[i])
                                i = i + 1
                                // Extract the Right Channel Sample if one exists.
                                if (channelCount == 2)
                                {
                                    totalRight = totalRight + Int64(sampleArray[i])
                                    i = i + 1
                                }
                                // Once done both (if applicable) we have processed ONE Sample that had two channels.
                                sampleTally = sampleTally + 1
                                
                                if (sampleTally > samplesPerPixel)
                                {
                                    // So what we really are doing is to take a number of Samples
                                    // and AVERAGE them so that we represent all those Samples
                                    // into one pixel or one verticle line in the graph per loop
                                    // of this code.
                                    var left = Int16(ceil(Double(totalLeft)/Double(sampleTally)))
                                    // It looks like 'songMaxSignal' is the Maximum Sample height
                                    // of either Channel across all samples being processed.
                                    // What good is this?  It allows us to create a factor later
                                    // in the algorithm so that we can keep the Graph within a
                                    // certain rectangular area.
                                    songMaxSignal = (left > songMaxSignal) ? left : songMaxSignal
                                    fullSongData.append(&left, length: MemoryLayout<Int16>.size)
                                    
                                    if (channelCount == 2)
                                    {
                                        var right = Int16(ceil(Double(totalRight)/Double(sampleTally)))
                                        songMaxSignal = (right > songMaxSignal) ? right : songMaxSignal
                                        fullSongData.append(&right, length: MemoryLayout<Int16>.size)
                                    }
                                    
                                    // So we have layed down a Left & Right Channel averaged
                                    // to a granularity of samplesPerPixel into an NSData 'fullSongData'.
                                    totalLeft   = 0
                                    totalRight  = 0
                                    sampleTally = 0
                                }
                            }
                            CMSampleBufferInvalidate(sampleBuffer)
                        }
                    }
                    if reader.status == AVAssetReaderStatus.failed || reader.status == AVAssetReaderStatus.unknown
                    {
                        completion(nil, UIImageErrors.assetReaderFailure(errorMessage: "AVAssetReader has failed to read the data while making a Graph File in \(#function).  System error is \(reader.error?.localizedDescription)"))
                        return
                    }
                    if reader.status == AVAssetReaderStatus.completed
                    {
                        // We have compressed the data via whatever algorithm we have chosen above.
                        // Bottom line is that we will be drawing the graph from the samples that now exist in the fullSongData.
                        //  Therefore it is important to get this new sample count so that drawing to the Image can accurate.
                        var samplesToGraph: [Int16] = [Int16](repeating: 0, count:fullSongData.length)
                        fullSongData.getBytes(&samplesToGraph, length: fullSongData.length * MemoryLayout<Int16>.size)
                        let (songGraphImage, error) = UIImage.drawAudioImageGraph(withSamples: samplesToGraph, songMaxSignal: Int(songMaxSignal), sampleCount: samplesToGraph.count, channelCount: channelCount, pixelsPerSecond: pixelsPerSecond, songLengthInSecs: songLengthInSecs,maxImageHeight: graphMaxHeight)
                        if let error = error
                        {
                            completion(nil, error)
                        }
                        else
                        {
                            completion(songGraphImage, nil)
                        }
                        return
                        // Need to write pixelsPerSecond to the parent Song!
                        // parentSong.songGraphPixelsPerSecond = @(pixelsPerSecond);
                    }
                }
                catch let err
                {
                    completion(nil, UIImageErrors.osLevelError(errorMessage: "Failed to spin up an Asset Reader. System error is: \(err.localizedDescription)"))
                    return
                }
        })
        return
    }
    
    //MARK: samples has (-) values in it.
    class func drawAudioImageGraph(withSamples samples: Array<Int16>, songMaxSignal: Int, sampleCount: Int, channelCount: UInt32, pixelsPerSecond: UInt, songLengthInSecs: TimeInterval, maxImageHeight: Int) -> (UIImage?, UIImageErrors?)
    {
        // So we will graph 2 channels where each wave has an upper and lower region with a space in the center and insets on the top and bottom:
        //
        //          +-----------------------+
        //          +       Top Margin      +
        //          + ----Left Channel ---- +
        //          +     Middle Margin     +
        //          + --- Right channel --- +
        //          +     Bottom Margin     +
        //          + - Time Number Line -- +
        //          + - Number Line Margin  +
        //          +-----------------------+
        
        guard let printingFont: UIFont = UIFont(name: UIImage.kFontName, size: CGFloat(UIImage.kFontSize))
            else
        {
            return (nil, UIImageErrors.fontNotLoaded(errorMessage: "Unable to load font \(UIImage.kFontName) in \(#function)!"))
        }
        
        let fontAttributes: [String : Any] = [NSFontAttributeName : UIFont(name: UIImage.kFontName, size: CGFloat(UIImage.kFontSize)) as Any]
        
        // From our samples of all channels involved we have kept track of the maximum 
        // wave height possible in 'songMaxSignal'.
        // Given this we want to create a factor based on the maximum area or height that 
        // we have to work with when drawing the data.
        // Ex: Say we have 250 pixels of space on which to draw the wave above or below.
        //     We then divide this by the maximum in the sample which is say 100.
        //     250 / 100 = 2.5.  So when we get a sample value we multiply by this factor 
        //     in order to make the result fit into our 250 pixel are.
        //     So that is 100 multiplied by the factor 2.5 and mark that value at 250; any
        //     value below that will map below that pixel.
        let sampleAdjustmentFactor: CGFloat = CGFloat(kWaveMaxHeight) / CGFloat(songMaxSignal)
        
        let topHalfHeight: Float = Float(UIImage.kGraphTopMargin + (UIImage.kWaveMaxHeight * 2) + UIImage.kGraphMiddleMargin)
        let bottomHalfHeight: Float = Float((UIImage.kWaveMaxHeight * 2) + UIImage.kGraphBottomMargin)
        let lineNumberHeight: Float = Float(UIImage.kTimeNumberLineHeight + UIImage.kTimeLineNumberLineTextMargin)
        
        // Painted screen height should dictate height minimum.
        let totalImageHeight: Float = Float(ceil(topHalfHeight + bottomHalfHeight + lineNumberHeight)) > Float(maxImageHeight) ? Float(ceil(topHalfHeight + bottomHalfHeight + lineNumberHeight)) : Float(maxImageHeight)
        
        // From the number line we will draw tick marks upwards:
        // TIME_NUMBER_LINE_SECOND_MARK_HEIGHT on the second markings.
        // TIME_NUMBER_LINE_QUARTER_SECOND_MARK_HEIGHT on the quarter second markings.
        let part1: Float = Float(UIImage.kGraphTopMargin + (UIImage.kWaveMaxHeight * 2))
        let part2: Float = Float(UIImage.kGraphMiddleMargin + (UIImage.kWaveMaxHeight * 2))
        let part3: Float = Float(UIImage.kTimeNumberLineHeight)
        let numberLineBottom: Float = part1 + part2 + part3
        
        // The width of the resulting Graphic is really the number of samples to be drawn.
        let totalSongGraphWidth: Int = Int(Int(ceil(songLengthInSecs)) * Int(pixelsPerSecond))
        let imageSize: CGSize = CGSize(width: totalSongGraphWidth, height: Int(totalImageHeight))
        
        UIGraphicsBeginImageContext(imageSize)
        
        guard let context: CGContext = UIGraphicsGetCurrentContext()
            else
        {
            return (nil, UIImageErrors.graphicsContextMissing(errorMessage: "Failed to obtain a Graphics Context!"))
        }
        
        context.setAlpha(1)
        var rect: CGRect = CGRect()
        rect.size = imageSize
        rect.origin.x = 0
        rect.origin.y = 0
        
        let leftColor: CGColor = UIImage.kGraphColorLeftChannel.cgColor
        let rightColor: CGColor = UIImage.kGraphColorRightChannel.cgColor
        let timeLineColor: CGColor = UIImage.kGraphColorTimeLine.cgColor
        
        let backgroundColor: UIColor = UIImage.kGraphColorBackground
        context.setFillColor(backgroundColor.cgColor)
        context.fill(rect)
        
        // This is the middle of the Left Channel.
        let centerLeft: CGFloat = CGFloat(UIImage.kGraphTopMargin + UIImage.kWaveMaxHeight)
        // This is the middle of the Right Channel.
        let centerRight: CGFloat = CGFloat(UIImage.kGraphTopMargin + (UIImage.kWaveMaxHeight * 2) + UIImage.kGraphMiddleMargin + UIImage.kWaveMaxHeight)
        
        // Draw line marking the time scale horizontal.
        context.setLineWidth(CGFloat(kTimeNumberLineThickness))
        context.move(to: CGPoint(x: 0, y: Int(numberLineBottom)))
        context.addLine(to: CGPoint(x: sampleCount, y: Int(numberLineBottom)))
        context.setStrokeColor(timeLineColor)
        context.strokePath()
        
        let pixelsPerFiveSecondInterval: Int = Int(pixelsPerSecond) * 5;
        let pixelsPerMinute: Int = Int(pixelsPerSecond) * 60;
        
        // We need to decide whether the 5 second tick marks are far enough appart to allow the labeling to show up.
        // If not we will try to use the number only and failing that none at all!
        var worstCase: String = "99 SEC"
        var useFiveSecUnitsLabel: Bool = true
        
        var sizeOfWorstCase:CGSize = (worstCase as NSString).size(attributes: fontAttributes)
        
        var showFiveSecondLabels = CGFloat(pixelsPerFiveSecondInterval) > (sizeOfWorstCase.width + CGFloat(UIImage.kTimeLineNumberLineTextMarkerMargin))
        
        if showFiveSecondLabels == false
        {
            worstCase = "99"
            sizeOfWorstCase = (worstCase as NSString).size(attributes: fontAttributes)
            showFiveSecondLabels = CGFloat(pixelsPerFiveSecondInterval) > (sizeOfWorstCase.width + CGFloat(UIImage.kTimeLineNumberLineTextMarkerMargin))
            if showFiveSecondLabels == true
            {
                // The spacing is too tight to show the units, i.e. SEC.
                useFiveSecUnitsLabel = false
            }
        }
        
        var currentMinute: Int = 0
        var currentFiveSecond: Int = 0
        var currentColumn: Int = 0
        var sampleIndex: Int = 0
        while sampleIndex < (sampleCount - 1)
        {
            let left: Int16 = abs(samples[sampleIndex])
            var pixels: CGFloat = CGFloat(left)
            
            // Notice that our representation of the sound height is cut in half so
            // that we show it as as centered on a base line, half above and half below (maxWaveHeight).
            pixels = pixels * sampleAdjustmentFactor
            
            // Need to spin and draw the same sample because we need to take up all the pixels that this sample represents on the time scale.
            
            let lineStartPoint = CGPoint(x: CGFloat(currentColumn), y: centerLeft - pixels)
            let lineEndPoint = CGPoint(x: CGFloat(currentColumn), y: centerLeft + pixels)
            context.setStrokeColor(leftColor)
            context.move(to: lineStartPoint)
            context.addLine(to: lineEndPoint)
            context.strokePath()
            
            if channelCount == 2
            {
                sampleIndex = sampleIndex + 1
                let right: Int16 = samples[sampleIndex]
                pixels = CGFloat(right)
                
                pixels = pixels * sampleAdjustmentFactor
                
                
                let lineStartPoint = CGPoint(x: CGFloat(currentColumn), y: centerRight - pixels)
                let lineEndPoint = CGPoint(x: CGFloat(currentColumn), y: centerRight + pixels)
                context.setStrokeColor(rightColor)
                context.move(to: lineStartPoint)
                context.addLine(to: lineEndPoint)
                context.strokePath()
            }
            
            // We will see what drawing a stroke every Second looks like!
            let onSecondBoundary: Bool = (UInt(currentColumn) % pixelsPerSecond) == 0
            let onFiveSecondBoundary: Bool = (currentColumn % pixelsPerFiveSecondInterval) == 0
            let onMinuteBoundary: Bool = (currentColumn % pixelsPerMinute) == 0
            
            if onSecondBoundary && !onFiveSecondBoundary && !onMinuteBoundary
            {
                context.setLineWidth(CGFloat(UIImage.kTimeNumberLineOneSecondMarkThickness))
                context.setStrokeColor(timeLineColor)
                context.move(to: CGPoint(x: CGFloat(currentColumn), y: CGFloat(numberLineBottom) - CGFloat(UIImage.kTimeNumberLineOneSecondMarkHeight)))
                context.addLine(to: CGPoint(x: CGFloat(currentColumn), y: CGFloat(numberLineBottom)))
                context.strokePath()
            }
            
            // Draw the five second boundary tick marks.
            if onFiveSecondBoundary && !onMinuteBoundary
                
            {
                currentFiveSecond = currentFiveSecond + 5
                context.setLineWidth(CGFloat(UIImage.kTimeNumberLineFiveSecondMarkThickness))
                context.setStrokeColor(timeLineColor)
                context.move(to: CGPoint(x: CGFloat(currentColumn), y: (CGFloat(numberLineBottom) - CGFloat(UIImage.kTimeNumberLineFiveSecondMarkHeight))))
                context.addLine(to: CGPoint(x: CGFloat(currentColumn), y: CGFloat(numberLineBottom)))
                context.strokePath()
                
                if showFiveSecondLabels == true
                {
                    var refPoint: CGPoint = CGPoint(x: CGFloat(currentColumn), y: CGFloat(CGFloat(numberLineBottom) + CGFloat(UIImage.kTimeLineNumberLineTextMargin / 2)))

                    let valueInInterval: Int = currentFiveSecond % 60
                    if useFiveSecUnitsLabel == true
                    {
                        refPoint.y = refPoint.y + CGFloat(UIImage.kTimeLineNumberLineTextMarkerOffset)
                        UIImage.printUnitFrom(refPoint: refPoint, itsValue: valueInInterval, inContext: context, usingUnit: "sec", andAddedUnit: currentMinute, andFont: printingFont)
                    }
                    else
                    {
                        UIImage.printUnitFrom(refPoint: refPoint, itsValue: valueInInterval, inContext: context, usingUnit: nil, andAddedUnit: 0, andFont: printingFont)
                    }
                }
            }
            
            // Draw the full minute boundary tick marks.
            if onMinuteBoundary == true
            {
                context.setLineWidth(CGFloat(UIImage.kTimeNumberLineMinuteMarkThickness))
                context.setStrokeColor(timeLineColor)
                context.move(to: CGPoint(x: CGFloat(currentColumn), y: CGFloat(numberLineBottom) - CGFloat(UIImage.kTimeNumberLineMinuteMarkHeight)))
                context.addLine(to: CGPoint(x: CGFloat(currentColumn), y: CGFloat(numberLineBottom)))
                context.strokePath()

                var refPoint: CGPoint = CGPoint(x: CGFloat(currentColumn), y: CGFloat(numberLineBottom) + CGFloat(UIImage.kTimeLineNumberLineTextMargin / 2))
                
                // onMinuteBoundary will be true at the very start so we have to detect
                // being at least one sample down the way.
                if currentColumn > 0
                {
                    refPoint.y = refPoint.y + CGFloat(UIImage.kTimeLineNumberLineTextMarkerOffset)
                    currentMinute = currentMinute + 1
                    UIImage.printUnitFrom(refPoint: refPoint, itsValue: currentMinute, inContext: context, usingUnit: "min", andAddedUnit: 0, andFont: printingFont)
                    currentFiveSecond = currentFiveSecond + 5
                }
            }
            currentColumn = currentColumn + 1
            sampleIndex = sampleIndex + 1
        }
        // Create new image
        if let newImage = UIGraphicsGetImageFromCurrentImageContext()
        {
            // Tidy up
            UIGraphicsEndImageContext()
            
            return (newImage, nil)
        }
        return (nil, UIImageErrors.imageNotObtainedFromContext)
    }
    
    class func printUnitFrom(refPoint: CGPoint, itsValue: Int, inContext: CGContext, usingUnit: String?, andAddedUnit: Int, andFont: UIFont) -> Void
    {
        // Preserve callers Context by pushing it onto a stack.
        inContext.saveGState()
        
        var minuteStr: String? = nil
        
        // The addedUnit is for labels > 1 Minute. It basically shows what minute this 5 second interval is inside.
        if andAddedUnit >= 1
        {
            minuteStr = "\(andAddedUnit) min"
            UIImage.printUnitLabel(forValue: minuteStr!, inContext: inContext, atPoint: refPoint, withFont: andFont)
            let fontAttributes: [String : Any] = [NSFontAttributeName : UIFont(name: UIImage.kFontName, size: CGFloat(UIImage.kFontSize)) as Any]
            let textSize: CGSize = (minuteStr! as NSString).size(attributes: fontAttributes)
            
            let newRefPoint: CGPoint = CGPoint(x: refPoint.x, y: refPoint.y + textSize.height)

            if let usingUnit = usingUnit
            {
                minuteStr = "\(itsValue) \(usingUnit)"
            }
            else
            {
                minuteStr = "\(itsValue)"
            }
            UIImage.printUnitLabel(forValue: minuteStr!, inContext: inContext, atPoint: newRefPoint, withFont: andFont)
        }
        else
        {
            if let usingUnit = usingUnit
            {
                minuteStr = "\(itsValue) \(usingUnit)"
            }
            else
            {
                minuteStr = "\(itsValue)"
            }
            UIImage.printUnitLabel(forValue: minuteStr!, inContext: inContext, atPoint: refPoint, withFont: andFont)
        }
        inContext.restoreGState()
    }
    
    class func printUnitLabel(forValue: String, inContext: CGContext, atPoint: CGPoint, withFont: UIFont) -> Void
    {
        // Preserve callers Context by pushing it onto a stack.
        inContext.saveGState()
        
        let timeNumberColor: UIColor = UIImage.kGraphColorTimeNumberMarkers
        let timeLineLetterColor: UIColor = UIImage.kGraphColorTimeNumberLetters
        let fontAttributes: [String : Any] = [NSFontAttributeName : UIFont(name: withFont.fontName, size: withFont.pointSize) as Any, NSForegroundColorAttributeName : timeNumberColor]
        let valueToBePrinted: NSString = forValue as NSString
        let textSize: CGSize = valueToBePrinted.size(attributes: fontAttributes)
        let halfTextWidth: CGFloat = textSize.width / 2
        let quarterTextHeight: CGFloat = textSize.height / 4
        // Draw the text.
        inContext.setShouldAntialias(true)
        inContext.setTextDrawingMode(CGTextDrawingMode.fill)
        inContext.setStrokeColor(timeLineLetterColor.cgColor)
        // Have to invert the Y coordinate system.
        inContext.textMatrix = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        let textPoint: CGPoint = CGPoint(x: atPoint.x - halfTextWidth, y: atPoint.y + quarterTextHeight)
        valueToBePrinted.draw(at: textPoint, withAttributes: fontAttributes)
        
        inContext.restoreGState()
    }
}
