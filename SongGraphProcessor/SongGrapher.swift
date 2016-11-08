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
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        if let songChosen = songChosen
        {
            UIImage.image(fromSong: songChosen, graphMaxWidth: Int(view.bounds.size.width * SongGrapher.sizeFactor), graphMaxHeight: Int(view.bounds.size.height), completion: {
                [weak self] (songImage, imageError)
                in
                if let strongSelf = self
                {
                    DispatchQueue.main.async
                        {
                            if let imageError = imageError
                            {
                                CentralCode.showError(message: imageError.localizedDescription, title: "Song Graph Error", onView: strongSelf)
                                return
                            }
                            else
                            {
                                let scrollView: UIScrollView = UIScrollView(frame: strongSelf.view.frame)
                                let imageView: UIImageView = UIImageView(image: songImage)
                                scrollView.addSubview(imageView)
                                scrollView.contentSize = imageView.frame.size
                                strongSelf.view.addSubview(scrollView)
                            }
                    }
                }
                
            })
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()

    }
}
