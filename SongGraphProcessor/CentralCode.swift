//
//  CentralCode.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-11-08.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CentralCode
{
    class func showError(message: String, title: String, onViewController: UIViewController)
    {
        let errorBox: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okButton: UIAlertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        errorBox.addAction(okButton)
        onViewController.present(errorBox, animated: true, completion: nil)
    }
    
    class func askOk(message: String, title: String, onViewController: UIViewController, okAction: @escaping ((UIAlertAction) -> Swift.Void), cancelAction: @escaping ((UIAlertAction) -> Swift.Void))
    {
        let okBox: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okButton: UIAlertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: okAction)
        okBox.addAction(okButton)
        let cancelButton = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: cancelAction)
        okBox.addAction(cancelButton)
        onViewController.present(okBox, animated: true, completion: nil)
    }
    
    class func runInMainThread(code: @escaping ()-> Void) -> Void
    {
        DispatchQueue.main.async
            {
                code()
        }
    }
    
    class func startSpinner(onView: UIView) -> UIActivityIndicatorView
    {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        DispatchQueue.main.async
            {
                spinner.center = onView.center
                onView.addSubview(spinner)
                onView.bringSubview(toFront: spinner)
                spinner.startAnimating()
        }
        return spinner
    }
    
    class func stopSpinner(_ theSpinner: UIActivityIndicatorView?)
    {
        if let hasSpinner = theSpinner
        {
            DispatchQueue.main.async
                {
            hasSpinner.stopAnimating()
            hasSpinner.removeFromSuperview()
            }
        }
    }
}
