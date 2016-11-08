//
//  CentralCode.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-11-08.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation
import UIKit
class CentralCode
{
    class func showError(message: String, title: String, onView: UIViewController)
    {
        let errorBox: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okButton: UIAlertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        let cancelButton: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        errorBox.addAction(okButton)
        errorBox.addAction(cancelButton)
        onView.present(errorBox, animated: true, completion: nil)
    }
    
    class func runInMainThread(code: @escaping ()-> Void) -> Void
    {
        DispatchQueue.main.async
            {
                code()
        }
    }
}
