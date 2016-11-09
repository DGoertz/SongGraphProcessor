//
//  SongGrapher.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-11-04.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import UIKit
import MediaPlayer

class SongGrapher : UIViewController
{
    static let sizeFactor: CGFloat = 10
    
    var songImage: UIImage?
    var songChosen: MPMediaItem?
    var spinner: UIActivityIndicatorView!
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        if let songChosen = songChosen
        {
            self.spinner = CentralCode.startSpinner(onView: self.view)
            if BundleWrapper.doesAudioGraphFileExist(forSong: songChosen)
            {
                if let songGraphURL = BundleWrapper.getAudioGraphFileURL(forSong: songChosen)
                {
                    if let songImage: UIImage = UIImage(contentsOfFile:
                        songGraphURL.path)
                    {
                        CentralCode.stopSpinner(self.spinner)
                        self.spinner = nil
                        self.putUpSongGraph(graph: songImage)
                        return
                    }
                }
            }
            // Assumption at this point is that the Song has been copied from the iPod
            // store to what is called the Import Cache File.
            UIImage.image(fromSong: songChosen, graphMaxWidth: Int(view.bounds.size.width * SongGrapher.sizeFactor), graphMaxHeight: Int(view.bounds.size.height), completion:
                {
                    [weak self] (songImage, imageError)
                    
                    in
                    
                    if let strongSelf = self
                    {
                        CentralCode.runInMainThread(code:
                            {
                                if let imageError = imageError
                                {
                                    CentralCode.showError(message: imageError, title: "Song Graph Error", onView: strongSelf)
                                    return
                                }
                                else
                                {
                                    if let songImage = songImage
                                    {
                                        strongSelf.putUpSongGraph(graph: songImage)
                                        CentralCode.stopSpinner(strongSelf.spinner)
                                        strongSelf.spinner = nil
                                        BundleWrapper.removeAudioGraphFileIfNeeded(forSong: songChosen)
                                        if let imagePath = BundleWrapper.getAudioGraphFileURL(forSong: songChosen)
                                        {
                                            if let pngRepresentation = UIImagePNGRepresentation(songImage)
                                            {
                                                do
                                                {
                                                    try pngRepresentation.write(to: imagePath)
                                                }
                                                catch let error
                                                {
                                                    CentralCode.showError(message: "Failed to write out the  Song Graph Image to a File! OS level error is: \(error.localizedDescription)", title: "Song Graph Error", onView: strongSelf)
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
                                            CentralCode.showError(message: "Failed to obtain the name and path of the Song Graph File!", title: "Song Graph Error", onView: strongSelf)
                                            return
                                        }
                                    }
                                    else
                                    {
                                        CentralCode.showError(message: "Song Graph Image is nil!", title: "Song Graph Error", onView: strongSelf)
                                        return
                                    }
                                }
                        })
                    }
                    
            })
            
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
