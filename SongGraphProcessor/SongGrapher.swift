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
            UIImage.image(fromSong: songChosen, graphMaxWidth: Int(self.songGraph.frame.size.width), completion: {
                [weak self] (songImage)
                in
                if let strongSelf = self
                {
                    DispatchQueue.main.async {
                        strongSelf.scrollView.frame = strongSelf.view.frame
                        strongSelf.songGraph.image = songImage
                        strongSelf.scrollView.addSubview(strongSelf.songGraph)
                        strongSelf.scrollView.contentSize = strongSelf.scrollView.bounds.size
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
