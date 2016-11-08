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
        errorBox.addAction(okButton)
        onView.present(errorBox, animated: true, completion: nil)
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
        print("Spinner Starting!")
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
        spinner.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        onView.addSubview(spinner)
        spinner.startAnimating()
        return spinner
    }
    
    class func stopSpinner(_ theSpinner: UIActivityIndicatorView)
    {
        print("Spinner Stopping!")
        theSpinner.stopAnimating()
        theSpinner.removeFromSuperview()
    }
}
