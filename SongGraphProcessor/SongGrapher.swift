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
    var songImage: UIImage?
    var songChosen: MPMediaItem?
    var spinner: UIActivityIndicatorView!
    
    static let pixelsPerSecond: Int = 50
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        let context: NSManagedObjectContext = CentralCode.getDBContext()
        if let songChosen = songChosen
        {
            self.spinner = CentralCode.startSpinner(onView: self.view)
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
            // Assumption at this point is that the Song has been copied from the iPod
            // store to what is called the Import Cache File.
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
                                    strongSelf.putUpSongGraph(graph: songImage)
                                    CentralCode.stopSpinner(strongSelf.spinner)
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
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        
    }
    
    func putUpSongGraph(graph: UIImage)
    {
        let scrollView: UIScrollView = UIScrollView(frame: self.view.frame)
        let imageView: UIImageView = UIImageView(image: graph)
        scrollView.addSubview(imageView)
        scrollView.contentSize = imageView.frame.size
        self.view.addSubview(scrollView)
    }
}
