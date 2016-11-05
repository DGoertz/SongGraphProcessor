//
//  SongGrapher.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-11-04.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import UIKit

class SongGrapher : UIViewController
{
    var songImage: UIImage?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var songGraph: UIImageView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let songImage = songImage
        {
            songGraph.image = songImage
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()

    }
}
