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
        spinner.center = onView.center
        onView.addSubview(spinner)
        spinner.startAnimating()
        return spinner
    }
    
    class func stopSpinner(_ theSpinner: UIActivityIndicatorView?)
    {
        theSpinner?.stopAnimating()
        theSpinner?.removeFromSuperview()
    }
    
    class func getDBContext() -> NSManagedObjectContext
    {
        guard let myApp = (UIApplication.shared.delegate) as? AppDelegate else {
            print("Failed to obtain the Application Delegate!")
            abort()
        }
        // This is needed for the unique constraint defined in PracticeItem.
        myApp.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return myApp.persistentContainer.viewContext
    }
}
