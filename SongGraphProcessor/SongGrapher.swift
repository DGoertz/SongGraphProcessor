//
//  SongGrapher.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-11-04.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import UIKit
import MediaPlayer
import CoreData

enum ScreenMode
{
    case playing
    case recording
    case paused
}

class SongGrapher : UIViewController, UIScrollViewDelegate
{
    var currentMode: ScreenMode = .paused
    var songChosen: MPMediaItem?
    var songImage:  UIImage?
    var song:       Song?
    var currentPI:  PracticeItem?
    
    var timer:      Timer?
    var songPlayer: AVAudioPlayer?
    var spinner:    UIActivityIndicatorView!
    var scrollView: UIScrollView?
    var reticle:    UIImageView?
    
    let context:    NSManagedObjectContext = CentralCode.getDBContext()
    
    var halfScreenWidth: CGFloat = 0
    var lastScreenHalfWidth:  CGFloat = 0
    
    static let pixelsPerSecond: CGFloat = 50
    static let tabBarHeight:    CGFloat = 45
    
    // MARK: GUI Contol References.
    @IBOutlet weak var playButton: UIBarButtonItem!
    
    @IBOutlet weak var pauseButton: UIBarButtonItem!
    
    @IBOutlet weak var rewindButton: UIBarButtonItem!
    
    @IBOutlet weak var fastForward5: UIBarButtonItem!
    
    @IBOutlet weak var fastBackward5: UIBarButtonItem!
    
    @IBOutlet weak var startPracticeItem: UIBarButtonItem!
    
    @IBOutlet weak var endPracticeItem: UIBarButtonItem!
    
    // MARK: GUI Contol Methods.
    
    @IBAction func playPressed(_ sender: UIBarButtonItem) {
        if let songPlayer = self.songPlayer
        {
            if songPlayer.isPlaying
            {
                return
            }
            songPlayer.prepareToPlay()
            songPlayer.play()
            self.currentMode = .playing
            return
        }
        CentralCode.showError(message: "Song Player not Initialized", title: "Song Player Error", onViewController: self)
    }
    
    @IBAction func pausePressed(_ sender: UIBarButtonItem)
    {
        if let songPlayer = self.songPlayer
        {
            if !songPlayer.isPlaying
            {
                return
            }
            songPlayer.pause()
            self.currentMode = .paused
            return
        }
        CentralCode.showError(message: "Song Player not Initialized", title: "Song Player Error", onViewController: self)
    }
    
    @IBAction func rewindPressed(_ sender: UIBarButtonItem)
    {
        if let songPlayer = self.songPlayer
        {
            if songPlayer.isPlaying
            {
                songPlayer.pause()
            }
            songPlayer.currentTime = 0
            self.rewindReticleAndSongGraphImage()
            songPlayer.prepareToPlay()
            self.currentMode = .paused
            return
        }
        CentralCode.showError(message: "Song Player not Initialized", title: "Song Player Error", onViewController: self)
    }
    
    @IBAction func plus5(_ sender: UIBarButtonItem)
    {
        if self.songChosen != nil
        {
            self.songPlayer!.currentTime = (self.songPlayer!.currentTime + 5) <= self.songChosen!.playbackDuration ? (self.songPlayer!.currentTime + 5) : self.songChosen!.playbackDuration
            self.realignReticleAndSongGraphToSongPlayer()
        }
    }
    
    @IBAction func minus5(_ sender: UIBarButtonItem)
    {
        self.songPlayer!.currentTime = (self.songPlayer!.currentTime - 5 > 0) ? self.songPlayer!.currentTime - 5 : 0
        self.realignReticleAndSongGraphToSongPlayer()
    }
    
    @IBAction func markStart(_ sender: UIBarButtonItem)
    {
        if self.song != nil && self.songPlayer != nil
        {
            if self.songPlayer!.isPlaying && self.currentPI == nil
            {
                self.currentPI = PracticeItem(context: context)
                self.currentPI!.forSong = song
                self.currentPI!.startTime = self.songPlayer!.currentTime
                self.currentMode = .recording
            }
        }
    }
    
    @IBAction func markEnd(_ sender: UIBarButtonItem)
    {
        if self.currentPI != nil && self.song != nil && self.songPlayer != nil
        {
            if self.songPlayer!.isPlaying
            {
                self.currentPI!.endTime = self.songPlayer!.currentTime
                self.getPracticeItemName(onViewController: self)
                // Have to pause it here since the Ok button doesn't run till
                // much later.
                self.currentMode = .paused
                self.songPlayer!.pause()
            }
        }
    }
    
    // MARK: UIView Methods.
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        self.view.isUserInteractionEnabled = true
        self.halfScreenWidth = self.view.frame.width / 2
        self.loadSongGraph()
        self.loadSongPlayer()
        self.startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        if let timer = self.timer
        {
            self.stopTimer(theTimer: timer)
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Timer Methods.
    
    func startTimer() -> Void
    {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block:
            {
                (theTime)
                in
                
                self.setControlsToState()
                if self.songPlayer != nil && self.reticle != nil  && self.scrollView != nil
                {
                    if self.songPlayer!.isPlaying
                    {
                        self.realignReticleAndSongGraphToSongPlayer()
                    }
                }
        })
    }
    
    func stopTimer(theTimer: Timer) -> Void
    {
        theTimer.invalidate()
    }
    
    func setControlsToState()
    {
        switch self.currentMode
        {
        case .paused:
            self.playButton.isEnabled = true
            self.pauseButton.isEnabled = false
            self.rewindButton.isEnabled = true
            self.fastForward5.isEnabled = true
            self.fastBackward5.isEnabled = true
            self.startPracticeItem.isEnabled = false
            self.endPracticeItem.isEnabled = false
        case .playing:
            self.playButton.isEnabled = false
            self.pauseButton.isEnabled = true
            self.rewindButton.isEnabled = true
            self.fastForward5.isEnabled = true
            self.fastBackward5.isEnabled = true
            self.startPracticeItem.isEnabled = true
            self.endPracticeItem.isEnabled = false
        case .recording:
            self.playButton.isEnabled = false
            self.pauseButton.isEnabled = false
            self.rewindButton.isEnabled = false
            self.fastForward5.isEnabled = false
            self.fastBackward5.isEnabled = false
            self.startPracticeItem.isEnabled = false
            self.endPracticeItem.isEnabled = true
        }
    }
    
    // MARK: SongPlayer Methods.
    
    func loadSongPlayer() -> Void
    {
        if let songChosen = self.songChosen, let url = songChosen.assetURL
        {
            do
            {
                self.songPlayer = try AVAudioPlayer(contentsOf: url)
            }
            catch let err
            {
                CentralCode.showError(message: "Failed to initialize the Song Player with the Chosen Song!  OS Error is: \(err.localizedDescription)", title: "Song Player Init Error", onViewController: self)
            }
        }
    }
    
    // MARK: Text Field Methods.
    
    func getPracticeItemName(onViewController: UIViewController)
    {
        let dialogBox: UIAlertController = UIAlertController(title: "Practice Item Name", message: "Enter a name?", preferredStyle: .alert)
        dialogBox.addTextField(configurationHandler: {
            (textField)
            
            in
            
            textField.placeholder = "Enter a 3 character name."
            textField.addTarget(self, action: #selector(self.textFieldDidChange), for: UIControlEvents.editingChanged)
        })
        let okButton: UIAlertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
            
            (UIAlertAction) -> Swift.Void
            
            in
            
            if let textFields = dialogBox.textFields, let textField = textFields.first, let text = textField.text
            {
                self.persistPracticeItem(withName: text.uppercased())
            }
        })
        dialogBox.addAction(okButton)
        okButton.isEnabled = false
        onViewController.present(dialogBox, animated: true, completion: nil)
    }
    
    @objc func textFieldDidChange(theTextField: UITextField) -> Void
    {
        if let alertViewController: UIAlertController = self.presentedViewController as! UIAlertController?
        {
            if let textFields = alertViewController.textFields, let textField = textFields.first, let text = textField.text
            {
                if let alertOkAction = alertViewController.actions.last
                {
                    alertOkAction.isEnabled = text.characters.count == 3
                }
            }
        }
    }
    
    // MARK: Db Methods.
    
    func persistPracticeItem(withName: String)
    {
        do
        {
            if self.currentPI != nil
            {
                self.currentPI!.name = withName
            }
            try self.context.save()
            if let newSongGraph: UIImage = try UIImage.drawPracticeItems(forSong: self.song!, withPixelsPerSecond: SongGrapher.pixelsPerSecond)
            {
                self.putUpSongGraph(graph: newSongGraph)
                self.realignReticleAndSongGraphToSongPlayer()
                self.currentPI = nil
            }
        }
        catch UIImageErrors.imageIsNotCGImage
        {
            CentralCode.showError(message: "Song Graph could not be converted into a CG Image!", title: "Drawing Practice Item Error", onViewController: self)
        }
        catch UIImageErrors.graphicsContextMissing(errorMessage: let errorMessage)
        {
            CentralCode.showError(message: "\(errorMessage)", title: "Drawing Practice Item Error", onViewController: self)
        }
        catch UIImageErrors.failedToGetImageFromContext
        {
            CentralCode.showError(message: "Image could not be obtained from the Core Graphics Context!", title: "Drawing Practice Item Error", onViewController: self)
        }
        catch let err
        {
            CentralCode.showError(message: "Error Saving Practice Item.  OS Error is: \(err.localizedDescription)", title: "DB Error", onViewController: self)
        }
    }
    
    // Currently I wait until I have a Graph before saving the Song.
    func updateSongInDb(inContext: NSManagedObjectContext, aSong: MPMediaItem, withGraph: Data) -> Song?
    {
        do
        {
            if try !Song.doesSongExist(inContext: inContext, mpItem: aSong)
            {
                let newSong = Song.addSong(toContext: inContext, mpItem: aSong, graph: withGraph)
                try inContext.save()
                return newSong
            }
            else
            {
                if let foundSong = try Song.updateSongGraph(inContext: inContext, mpItem: aSong, graph: withGraph)
                {
                    try inContext.save()
                    return foundSong
                }
            }
        }
        catch SongErrors.selectFailed(let errorMessage)
        {
            CentralCode.showError(message: errorMessage, title: "Song DB Read Error", onViewController: self)
            return nil
        }
        catch SongErrors.idIsNotUnique
        {
            CentralCode.showError(message: "Two songs were found with the same ID!", title: "Song DB Read Error", onViewController: self)
            return nil
        }
        catch SongErrors.saveFailed(let errorMessage)
        {
            CentralCode.showError(message: errorMessage, title: "Song DB Save Error", onViewController: self)
            return nil
        }
        catch let error
        {
            CentralCode.showError(message: "Failed to save the Song! OS level error is: \(error.localizedDescription)", title: "Song Graph Error", onViewController: self)
            return nil
        }
        return nil
    }
    
    func loadSongGraph() -> Void
    {
        if let songChosen = songChosen
        {
            self.spinner = CentralCode.startSpinner(onView: self.view)
            do
            {
                if let foundSong = try Song.getSong(inContext: context, mpItem: songChosen)
                {
                    if let songImage: UIImage = UIImage(data: foundSong.graph as! Data)
                    {
                        self.songImage = songImage
                        self.lastScreenHalfWidth = songImage.size.width - self.halfScreenWidth
                        self.song = foundSong
                        do
                        {
                            if let finalImage = try UIImage.drawPracticeItems(forSong: foundSong, withPixelsPerSecond: SongGrapher.pixelsPerSecond)
                            {
                                self.putUpSongGraph(graph: finalImage)
                            }
                        }
                        catch let err
                        {
                            CentralCode.showError(message: "\(err.localizedDescription)", title: "Error Showing Song Graph", onViewController: self)
                        }
                        CentralCode.stopSpinner(self.spinner)
                        return
                    }
                }
            }
            catch SongErrors.idIsNotUnique
            {
                CentralCode.showError(message: "Two songs were found with the same ID!", title: "Song Read Error", onViewController: self)
                CentralCode.stopSpinner(self.spinner)
                return
            }
            catch SongErrors.selectFailed(errorMessage: let errorMessage)
            {
                CentralCode.showError(message: errorMessage, title: "Song Read Error", onViewController: self)
                CentralCode.stopSpinner(self.spinner)
                return
            }
            catch let error
            {
                CentralCode.showError(message: "Song not found - OS ERROR is: \(error.localizedDescription)", title: "Song Read Error", onViewController: self)
                CentralCode.stopSpinner(self.spinner)
                return
            }
            // Assumption at this point is:
            // The Song is not in the DB or the graph is nil and that the Song has been
            // copied from the iPod library to what is called the Import Cache File.
            do
            {
                let graphHeight = self.view.frame.height - SongGrapher.tabBarHeight
                try UIImage.getImage(fromSong: songChosen, pixelsPerSecond: SongGrapher.pixelsPerSecond, graphMaxHeight: Int(graphHeight), completion:
                    
                    {
                        
                        [weak self] songImage
                        
                        in
                        
                        if let strongSelf = self
                        {
                            CentralCode.runInMainThread(code:
                                {
                                    // We've produced the Graph and don't need the Import file anymore.
                                    if BundleWrapper.doesImportCacheFileExist(forSong: songChosen)
                                    {
                                        let importCacheFileURL: URL = BundleWrapper.getImportCacheFileURL(forSong: songChosen)!
                                        do
                                        {
                                            try FileManager.default.removeItem(at: importCacheFileURL)
                                        }
                                        catch let error
                                        {
                                            CentralCode.showError(message: "Failed to clean up Import Cache File after producing a Song Graph: \(importCacheFileURL).  OS error is: \(error.localizedDescription)", title: "File Deletion Error", onViewController: strongSelf)
                                            CentralCode.stopSpinner(strongSelf.spinner)
                                            return
                                        }
                                    }
                                    if let songImage = songImage
                                    {
                                        strongSelf.songImage = songImage
                                        strongSelf.lastScreenHalfWidth = songImage.size.width - strongSelf.halfScreenWidth
                                        strongSelf.putUpSongGraph(graph: songImage)
                                        if let pngRepresentation = UIImagePNGRepresentation(songImage)
                                        {
                                            strongSelf.song = strongSelf.updateSongInDb(inContext: strongSelf.context, aSong: songChosen, withGraph: pngRepresentation)
                                            CentralCode.stopSpinner(strongSelf.spinner)
                                            return
                                        }
                                        else
                                        {
                                            CentralCode.showError(message: "Failed to convert the Song Graph Image to a PNG!", title: "Song Graph Error", onViewController: strongSelf)
                                            CentralCode.stopSpinner(strongSelf.spinner)
                                            return
                                        }
                                    }
                                    else
                                    {
                                        CentralCode.showError(message: "Song Graph Image is nil!", title: "Song Graph Error", onViewController: strongSelf)
                                        CentralCode.stopSpinner(strongSelf.spinner)
                                        return
                                    }
                            })
                        }
                })
            }
            catch let err
            {
                CentralCode.showError(message: "\(err.localizedDescription)", title: "Song Graph Error", onViewController: self)
                CentralCode.stopSpinner(self.spinner)
                return
            }
        }
    }
    
    // MARK: Artwork Methods.
    
    func realignSongPlayerToReticle()
    {
        if self.reticle != nil && self.songPlayer != nil
        {
            self.songPlayer!.currentTime = TimeInterval(self.reticle!.center.x / SongGrapher.pixelsPerSecond)
        }
    }
    
    func realignReticleAndSongGraphToSongPlayer()
    {
        let newPosition = CGPoint(x: CGFloat(self.songPlayer!.currentTime) * SongGrapher.pixelsPerSecond, y: self.scrollView!.center.y)
        if newPosition.x > self.halfScreenWidth && newPosition.x < self.lastScreenHalfWidth
        {
            self.reticle!.center = newPosition
            self.scrollView!.contentOffset = CGPoint(x: newPosition.x - self.halfScreenWidth, y: 0)
        }
        else
        {
            self.reticle!.center = newPosition
        }
    }
    
    func rewindReticleAndSongGraphImage()
    {
        if self.scrollView != nil && self.reticle != nil
        {
            self.scrollView!.contentOffset = CGPoint(x: 0, y: 0)
            self.reticle!.center = CGPoint(x: 0, y: self.scrollView!.center.y)
        }
    }
    
    func removePreviousScrollView()
    {
        if self.scrollView != nil
        {
            self.scrollView!.removeFromSuperview()
            self.scrollView = nil
        }
    }
    
    func putUpSongGraph(graph: UIImage) -> Void
    {
        self.removePreviousScrollView()
        let graphWindowFrame: CGRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.view.frame.width, height: self.view.frame.height - SongGrapher.tabBarHeight))
        self.scrollView = UIScrollView(frame: graphWindowFrame)
        if self.scrollView != nil
        {
            self.scrollView!.delegate = self
            self.scrollView!.isUserInteractionEnabled = true
            let imageView: UIImageView = UIImageView(image: graph)
            imageView.isUserInteractionEnabled = true
            self.scrollView!.addSubview(imageView)
            self.scrollView!.contentSize = imageView.frame.size
            self.view.addSubview(self.scrollView!)
            self.putUpReticle()
        }
    }
    
    func putUpReticle()
    {
        if let reticleImage: UIImage = UIImage(named: "PositionReticle.png")
        {
            self.reticle = UIImageView(image: reticleImage)
            self.reticle!.isUserInteractionEnabled = true
            self.reticle!.center = CGPoint(x: 0, y: self.scrollView!.center.y)
            self.scrollView!.addSubview(self.reticle!)
        }
    }
    
    func isThisTheSongGraph(thisScrollView: UIScrollView) -> Bool
    {
        if self.scrollView != nil
        {
            return thisScrollView == self.scrollView
        }
        return false
    }
    
    // MARK: UIScrollViewDelegate Methods.
    
    func fixArtworkAfterScroll(scrollView: UIScrollView)
    {
        if self.isThisTheSongGraph(thisScrollView: scrollView)
        {
            if self.reticle != nil
            {
                let newX: CGFloat = self.scrollView!.contentOffset.x + self.halfScreenWidth
                let newY: CGFloat = self.scrollView!.center.y
                self.reticle!.center = CGPoint(x: newX, y: newY)
                self.realignSongPlayerToReticle()
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        self.fixArtworkAfterScroll(scrollView: scrollView)
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        self.fixArtworkAfterScroll(scrollView: scrollView)
    }
}
