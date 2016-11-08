//
//  SongChooser.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-11-04.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import UIKit
import MediaPlayer

class SongChooser: UIViewController, MPMediaPickerControllerDelegate
{
    
    // MARK: Widget Connections.
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: Widget backing code.
    @IBAction func choosePressed(_ sender: Any)
    {
        displayMediaPicker()
    }
    
    // MARK: Constants.
    static let segueToSongGrapher: String = "toSongGrapher"
    
    // MARK: Properties.
    var chosenSong: MPMediaItem?
    var mediaPicker: MPMediaPickerController?
    
    // MARK: View Controller Delegate Methods.
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        statusLabel.text = ""
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        
    }
    
    // MARK: View Transition Methods.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == SongChooser.segueToSongGrapher, let nextVC = segue.destination as? SongGrapher, let chosenSong = self.chosenSong
        {
            nextVC.songChosen = self.chosenSong
            nextVC.title = (chosenSong.title != nil) ? chosenSong.title : "Unknown"
        }
    }
    
    func run(codeInMain: @escaping ()-> Void) -> Void
    {
        DispatchQueue.main.async
            {
                codeInMain()
        }
    }
    
    // MARK: Media Picker Methods.
    func displayMediaPicker()
    {
        self.mediaPicker = MPMediaPickerController(mediaTypes: MPMediaType.music)
        self.mediaPicker!.delegate = self
        self.mediaPicker!.allowsPickingMultipleItems = false
        self.mediaPicker!.showsCloudItems = false
        self.navigationController?.present(self.mediaPicker!, animated: true, completion: nil)
    }
    
    // MARK: MPMediaPickerControllerDelegate Functions.
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection)
    {
        self.chosenSong = mediaItemCollection.items[0]
        mediaPicker.dismiss(animated: true, completion: nil)
        
        guard let importCacheFileURL = BundleWrapper.getImportCacheFileURL(forSong: self.chosenSong!)
            else
        {
            mediaPicker.dismiss(animated: true, completion: nil)
            self.putUpError(message: "Failed to aquire a path for the temporary Import File!", title: "Song Choice Error")
            self.statusLabel.text = "Failed to aquire a path for the temporary Import File!"
            return
        }
        guard let inputURL = self.chosenSong!.assetURL
            else
        {
            mediaPicker.dismiss(animated: true, completion: nil)
            self.putUpError(message: "Failed to find a path to the chosen music File!", title: "Song Choice Error")
            self.statusLabel.text = "Failed to find a path to the chosen music File!"
            return
        }
        
            if let hasChosenASong = self.chosenSong
            {
                if BundleWrapper.doesImportCacheFileExist(forSong: hasChosenASong)
                {
                    self.performSegue(withIdentifier: SongChooser.segueToSongGrapher, sender: self)
                }
                else
                {
                    do
                    {
                        let importGuy = MediaImport()
                        try importGuy.doImport(inputURL, output: importCacheFileURL, completionCode:
                            {
                                [weak self] (importGuy) in
                                if let strongSelf = self
                                {
                                    if importGuy.status == AVAssetExportSessionStatus.completed
                                    {
                                        if FileManager.default.fileExists(atPath: importCacheFileURL.path)
                                        {
                                            strongSelf.run(codeInMain:
                                                {
                                                    strongSelf.performSegue(withIdentifier: SongChooser.segueToSongGrapher, sender: self)
                                            })
                                        }
                                        else
                                        {
                                            strongSelf.run(codeInMain:
                                                {
                                                    strongSelf.statusLabel.text = "Status good but file not found?"
                                            })
                                        }
                                    }
                                    else
                                    {
                                        strongSelf.run(codeInMain:                                {
                                            strongSelf.statusLabel.text = "Import status is not completed.  It is \(importGuy.status)"
                                        })
                                    }
                                }
                        })
                    }
                    catch let error
                    {
                        self.putUpError(message: error.localizedDescription, title: "Song Choice Error")
                    }
                    
                }
            }        
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController)
    {
        print("Song pick was canceled")
    }
    
    // MARK: Utility Methods.
    func putUpError(message: String, title: String)
    {
        let errorBox: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okButton: UIAlertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        let cancelButton: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        errorBox.addAction(okButton)
        errorBox.addAction(cancelButton)
        self.present(errorBox, animated: true, completion: nil)
    }
}

