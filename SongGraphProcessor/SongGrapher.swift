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

class SongGrapher : UIViewController
{
    var songImage:  UIImage?
    var songChosen: MPMediaItem?
    var spinner:    UIActivityIndicatorView!
    
    var timer:      Timer?
    var songPlayer: AVAudioPlayer?
    var scrollView: UIScrollView?
    var reticle:    UIImageView?
    
    static let pixelsPerSecond: Int     = 50
    static let tabBarHeight:    CGFloat = 45
    
    @IBOutlet weak var playButton: UIBarButtonItem!
    
    
    @IBAction func playButtonPressed(_ sender: Any)
    {
        if let songPlayer = self.songPlayer
        {
            if songPlayer.isPlaying
            {
                return
            }
            songPlayer.play()
            return
        }
        CentralCode.showError(message: "Song Player not Initialized", title: "Song Player Error", onView: self)
    }
    
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        self.loadSongGraph()
        self.loadSongPlayer()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func loadSongGraph() -> Void
    {
        self.spinner = CentralCode.startSpinner(onView: self.view)
        let context: NSManagedObjectContext = CentralCode.getDBContext()
        if let songChosen = songChosen
        {
            do
            {
                if let foundSong = try Song.getSong(inContext: context, mpItem: songChosen)
                {
                    if let songImage: UIImage = UIImage(data: foundSong.graph as! Data)
                    {
                        CentralCode.stopSpinner(self.spinner)
                        self.putUpSongGraph(graph: songImage)
                        return
                    }
                }
            }
            catch SongErrors.idIsNotUnique
            {
                CentralCode.showError(message: "Two songs were found with the same ID!", title: "Song Read Error", onView: self)
                return
            }
            catch SongErrors.selectFailed(errorMessage: let errorMessage)
            {
                CentralCode.showError(message: errorMessage, title: "Song Read Error", onView: self)
            }
            catch let error
            {
                CentralCode.showError(message: "Song not found - unknown error.  OS ERROR is: \(error.localizedDescription)", title: "Song Read Error", onView: self)
                return
            }
            // Assumption at this point is:
            // The Song is not in the DB or the graph is nil and that the Song has been
            // copied from the iPod library to what is called the Import Cache File.
            do
            {
                try UIImage.image(fromSong: songChosen, pixelsPerSecond: SongGrapher.pixelsPerSecond, graphMaxHeight: Int(view.bounds.size.height), completion: {
                    
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
                                        CentralCode.showError(message: "Failed to clean up Import Cache File after producing a Song Graph: \(importCacheFileURL).  OS error is: \(error.localizedDescription)", title: "File Deletion Error", onView: strongSelf)
                                    }
                                }
                                if let songImage = songImage
                                {
                                    CentralCode.stopSpinner(strongSelf.spinner)
                                    strongSelf.putUpSongGraph(graph: songImage)
                                    if let pngRepresentation = UIImagePNGRepresentation(songImage)
                                    {
                                        do
                                        {
                                            if try !Song.doesSongExist(inContext: context, mpItem: songChosen)
                                            {
                                                Song.addSong(toContext: context, mpItem: songChosen, graph: pngRepresentation)
                                                try context.save()
                                            }
                                            else
                                            {
                                                try Song.updateSongGraph(inContext: context, mpItem: songChosen, graph: pngRepresentation)
                                            }
                                        }
                                        catch SongErrors.selectFailed(let errorMessage)
                                        {
                                            CentralCode.showError(message: errorMessage, title: "Song DB Read Error", onView: strongSelf)
                                            return
                                        }
                                        catch SongErrors.idIsNotUnique
                                        {
                                            CentralCode.showError(message: "Two songs were found with the same ID!", title: "Song DB Read Error", onView: strongSelf)
                                            return
                                        }
                                        catch SongErrors.saveFailed(let errorMessage)
                                        {
                                            CentralCode.showError(message: errorMessage, title: "Song DB Read Error", onView: strongSelf)
                                            return
                                        }
                                        catch let error
                                        {
                                            CentralCode.showError(message: "Failed to write out the Song Graph Image to a File! OS level error is: \(error.localizedDescription)", title: "Song Graph Error", onView: strongSelf)
                                            return
                                        }
                                    }
                                    else
                                    {
                                        CentralCode.showError(message: "Failed to convert the Song Graph Image to a PNG!", title: "Song Graph Error", onView: strongSelf)
                                        return
                                    }
                                    
                                }
                                else
                                {
                                    CentralCode.showError(message: "Song Graph Image is nil!", title: "Song Graph Error", onView: strongSelf)
                                    return
                                }
                        })
                    }
                    
                })
            }
            catch let err
            {
                CentralCode.showError(message: "\(err.localizedDescription)", title: "Song Graph Error", onView: self)
                return
            }
        }
    }
    
    func putUpSongGraph(graph: UIImage) -> Void
    {
        let graphWindow: CGRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.view.frame.width, height: self.view.frame.height - SongGrapher.tabBarHeight))
        self.scrollView = UIScrollView(frame: graphWindow)
        let imageView: UIImageView = UIImageView(image: graph)
        self.scrollView?.addSubview(imageView)
        self.scrollView?.contentSize = imageView.frame.size
        self.view.addSubview(self.scrollView!)
        self.putUpReticle()
    }
    
    func putUpReticle()
    {
        if let reticleOverlay: UIImage = UIImage(named: "PositionReticle.png")
        {
            self.reticle = UIImageView(image: reticleOverlay)
            self.reticle?.center = CGPoint(x: 0, y: self.scrollView!.center.y)
            self.view.addSubview(self.reticle!)
        }
    }
    
    func startTimer() -> Void
    {
        let heartRate: TimeInterval = TimeInterval(floatLiteral: 0.1)
        self.timer = Timer.scheduledTimer(withTimeInterval: heartRate, repeats: true, block:
            {
                (theTime)
                in
                if self.songPlayer != nil
                {
                    let player = self.songPlayer
                    
                }
        })
    }
    
    func stopTimer(theTimer: Timer) -> Void
    {
        theTimer.invalidate()
    }
    
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
                CentralCode.showError(message: "Failed to initialize the Song Player with the Chosen Song!  OS Error is: \(err.localizedDescription)", title: "Song Player Init Error", onView: self)
            }
        }
    }
}
