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
    var songImage: UIImage?
    var songChosen: MPMediaItem?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var songGraph: UIImageView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let songChosen = songChosen
        {
            UIImage.image(fromSong: songChosen, graphMaxWidth: Int(scrollView.frame.size.width), completion: {
                (songImage)
                in
                DispatchQueue.main.async {
                    self.songGraph.image = songImage
                }
                
            })
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()

    }
}
