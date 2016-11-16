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
    
    var halfScreenWidth: CGFloat = 0
    var lastScreenHalfWidth:  CGFloat = 0
    
    static let pixelsPerSecond: CGFloat = 50
    static let tabBarHeight:    CGFloat = 45
    
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
            self.resetArtwork()
            songPlayer.prepareToPlay()
            return
        }
        CentralCode.showError(message: "Song Player not Initialized", title: "Song Player Error", onViewController: self)
    }
    
    @IBAction func plus5(_ sender: UIBarButtonItem)
    {
        if self.songPlayer != nil
        {
            self.songPlayer!.currentTime = self.songPlayer!.currentTime + 5
            self.realignArtwork()
        }
    }
    
    @IBAction func minus5(_ sender: UIBarButtonItem)
    {
        if self.songPlayer != nil
        {
            self.songPlayer!.currentTime = self.songPlayer!.currentTime - 5
            self.realignArtwork()
        }
    }
    
    // MARK: UIView Methods.
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
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
    
    func realignArtwork()
    {
        let newPosition = CGPoint(x: CGFloat(self.songPlayer!.currentTime) * SongGrapher.pixelsPerSecond, y: self.scrollView!.center.y)
        if newPosition.x > self.halfScreenWidth && newPosition.x < self.lastScreenHalfWidth
        {
            self.reticle!.center = CGPoint(x: newPosition.x, y: self.scrollView!.center.y)
            self.scrollView!.contentOffset = CGPoint(x: newPosition.x - self.halfScreenWidth, y: 0)
        }
        else
        {
            self.reticle!.center = newPosition
        }
    }
    
    func startTimer() -> Void
    {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block:
            {
                (theTime)
                in
                
                if self.songPlayer != nil && self.reticle != nil  && self.scrollView != nil
                {
                    if self.songPlayer!.isPlaying
                    {
                        self.realignArtwork()
                    }
                }
        })
    }
    
    func stopTimer(theTimer: Timer) -> Void
    {
        theTimer.invalidate()
    }
    
    // MARK: Utility Methods.
    
    func resetArtwork()
    {
        if self.scrollView != nil && self.reticle != nil
        {
            self.scrollView!.contentOffset = CGPoint(x: 0, y: 0)
            self.reticle!.center = CGPoint(x: 0, y: self.scrollView!.center.y)
        }
    }
    
    func updateSong(inContext: NSManagedObjectContext, aSong: MPMediaItem, withGraph: Data)
    {
        do
        {
            if try !Song.doesSongExist(inContext: inContext, mpItem: aSong)
            {
                Song.addSong(toContext: inContext, mpItem: aSong, graph: withGraph)
            }
            else
            {
                try Song.updateSongGraph(inContext: inContext, mpItem: aSong, graph: withGraph)
            }
            try inContext.save()
        }
        catch SongErrors.selectFailed(let errorMessage)
        {
            CentralCode.showError(message: errorMessage, title: "Song DB Read Error", onViewController: self)
            return
        }
        catch SongErrors.idIsNotUnique
        {
            CentralCode.showError(message: "Two songs were found with the same ID!", title: "Song DB Read Error", onViewController: self)
            return
        }
        catch SongErrors.saveFailed(let errorMessage)
        {
            CentralCode.showError(message: errorMessage, title: "Song DB Save Error", onViewController: self)
            return
        }
        catch let error
        {
            CentralCode.showError(message: "Failed to save the Song! OS level error is: \(error.localizedDescription)", title: "Song Graph Error", onViewController: self)
            return
        }
    }
    
    // Initialize GUI.
    
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
                        self.lastScreenHalfWidth = songImage.size.width - self.halfScreenWidth
                        self.putUpSongGraph(graph: songImage)
                        CentralCode.stopSpinner(self.spinner)
                        return
                    }
                }
            }
            catch SongErrors.idIsNotUnique
            {
                CentralCode.showError(message: "Two songs were found with the same ID!", title: "Song Read Error", onViewController: self)
                return
            }
            catch SongErrors.selectFailed(errorMessage: let errorMessage)
            {
                CentralCode.showError(message: errorMessage, title: "Song Read Error", onViewController: self)
            }
            catch let error
            {
                CentralCode.showError(message: "Song not found - OS ERROR is: \(error.localizedDescription)", title: "Song Read Error", onViewController: self)
                return
            }
            // Assumption at this point is:
            // The Song is not in the DB or the graph is nil and that the Song has been
            // copied from the iPod library to what is called the Import Cache File.
            do
            {
                let graphHeight = self.view.frame.height - SongGrapher.tabBarHeight
                try UIImage.image(fromSong: songChosen, pixelsPerSecond: SongGrapher.pixelsPerSecond, graphMaxHeight: Int(graphHeight), completion:
                    
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
                                        }
                                    }
                                    if let songImage = songImage
                                    {
                                        strongSelf.lastScreenHalfWidth = songImage.size.width - strongSelf.halfScreenWidth
                                        strongSelf.putUpSongGraph(graph: songImage)
                                        CentralCode.stopSpinner(strongSelf.spinner)
                                        if let pngRepresentation = UIImagePNGRepresentation(songImage)
                                        {
                                            strongSelf.updateSong(inContext: context, aSong: songChosen, withGraph: pngRepresentation)
                                        }
                                        else
                                        {
                                            CentralCode.showError(message: "Failed to convert the Song Graph Image to a PNG!", title: "Song Graph Error", onViewController: strongSelf)
                                            return
                                        }
                                        
                                    }
                                    else
                                    {
                                        CentralCode.showError(message: "Song Graph Image is nil!", title: "Song Graph Error", onViewController: strongSelf)
                                        return
                                    }
                            })
                        }
                        
                })
            }
            catch let err
            {
                CentralCode.showError(message: "\(err.localizedDescription)", title: "Song Graph Error", onViewController: self)
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
            self.reticle!.center = CGPoint(x: 0, y: self.scrollView!.center.y)
            self.scrollView!.addSubview(self.reticle!)
            //self.view.addSubview(self.reticle!)
        }
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
                CentralCode.showError(message: "Failed to initialize the Song Player with the Chosen Song!  OS Error is: \(err.localizedDescription)", title: "Song Player Init Error", onViewController: self)
            }
        }
    }
}
