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
    var spinner: UIActivityIndicatorView!
    
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
        print("Memory Issue!")
        super.didReceiveMemoryWarning()
    }
    
    // MARK: View Transition Methods.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == SongChooser.segueToSongGrapher, let nextVC = segue.destination as? SongGrapher, let chosenSong = self.chosenSong
        {
            nextVC.songChosen = self.chosenSong
            let titlePart1 = (chosenSong.title != nil) ? chosenSong.title! : "Unknown"
            let titlePart2 = (chosenSong.albumArtist !=  nil) ? chosenSong.albumArtist! : ""
            let titlePart3 = (chosenSong.albumTitle != nil) ? chosenSong.albumTitle! : ""
            let artistAndAlbum = "Song:\(titlePart1) - Artist:\(titlePart2) - Album:\(titlePart3)"
            nextVC.title = "\(artistAndAlbum)"
        }
    }
    
    // MARK: Media Picker Methods.
    func displayMediaPicker()
    {
        self.mediaPicker = MPMediaPickerController(mediaTypes: MPMediaType.music)
        self.mediaPicker!.delegate = self
        self.mediaPicker!.allowsPickingMultipleItems = false
        self.mediaPicker!.showsCloudItems = false
        if let hasNavController = self.navigationController
        {
            hasNavController.present(self.mediaPicker!, animated: true, completion: nil)
        }
        else
        {
            CentralCode.showError(message: "The Navigation Controller is invalid!  BUILD AGAIN!", title: "Internal Error", onView: self)
        }
    }
    
    // MARK: MPMediaPickerControllerDelegate Functions.
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection)
    {
        self.chosenSong = mediaItemCollection.items[0]
        if let hasChosenASong = self.chosenSong
        {
            guard let importCacheFileURL = BundleWrapper.getImportCacheFileURL(forSong: hasChosenASong)
                else
            {
                mediaPicker.dismiss(animated: true, completion: nil)
                if hasChosenASong.hasProtectedAsset == true
                {
                    CentralCode.showError(message: "Sorry that song is protected by DRM!", title: "Song Choice Error", onView: self)
                    self.statusLabel.text = "Sorry that song is protected by DRM!"
                }
                else
                {
                    CentralCode.showError(message: "Failed to aquire a path for the temporary Import File!  Note: This file is not DRM protected so who knows why?", title: "Song Choice Error", onView: self)
                    self.statusLabel.text = "Failed to aquire a path for the temporary Import File!"
                }
                return
            }
            // Preceding code guarntees that the assetURL is not nil!
            let inputURL: URL = hasChosenASong.assetURL!
            mediaPicker.dismiss(animated: true, completion: nil)
            if BundleWrapper.doesImportCacheFileExist(forSong: hasChosenASong)
            {
                self.performSegue(withIdentifier: SongChooser.segueToSongGrapher, sender: self)
            }
            else
            {
                do
                {
                    self.spinner = CentralCode.startSpinner(onView: self.view)
                    self.statusLabel.text = "Importing Song"
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
                                        CentralCode.runInMainThread(code:
                                            {
                                                CentralCode.stopSpinner(strongSelf.spinner)
                                                self?.statusLabel.text = ""
                                                strongSelf.performSegue(withIdentifier: SongChooser.segueToSongGrapher, sender: self)
                                        })
                                    }
                                    else
                                    {
                                        CentralCode.stopSpinner(strongSelf.spinner)
                                        self?.statusLabel.text = ""
                                        CentralCode.runInMainThread(code:
                                            {
                                                
                                                CentralCode.showError(message: "Import Status of music file is good but file was not found after copy?", title: "Import Error", onView: strongSelf)
                                                strongSelf.statusLabel.text = "Status good but file not found?"
                                        })
                                    }
                                }
                                else
                                {
                                    CentralCode.stopSpinner(strongSelf.spinner)
                                    self?.statusLabel.text = ""
                                    CentralCode.runInMainThread(code:
                                        {
                                            switch importGuy.status
                                            {
                                            case AVAssetExportSessionStatus.cancelled:
                                                CentralCode.showError(message: "Import Status is not completed.  Status is Cancelled", title: "Import Error", onView: strongSelf)
                                            case AVAssetExportSessionStatus.exporting:
                                                CentralCode.showError(message: "Import Status is not completed.  Status is Exporting", title: "Import Error", onView: strongSelf)
                                            case AVAssetExportSessionStatus.failed:
                                                CentralCode.showError(message: "Import Status is not completed.  Status is Failed", title: "Import Error", onView: strongSelf)
                                            case AVAssetExportSessionStatus.unknown:
                                                CentralCode.showError(message: "Import Status is not completed.  Status is Unknown", title: "Import Error", onView: strongSelf)
                                            case AVAssetExportSessionStatus.waiting:
                                                CentralCode.showError(message: "Import Status is not completed.  Status is Waiting", title: "Import Error", onView: strongSelf)
                                            default:
                                                CentralCode.showError(message: "Import Status is not completed.  Status is Fucked!", title: "Import Error", onView: strongSelf)
                                            }
                                    })
                                }
                            }
                    })
                }
                catch let error
                {
                    CentralCode.showError(message: error.localizedDescription, title: "Song Choice Error", onView: self)
                }
                
            }
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController)
    {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
}

