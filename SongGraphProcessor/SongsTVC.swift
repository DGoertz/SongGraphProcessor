//
//  SongsTVC.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-11-22.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MediaPlayer

class SongsTVC : UITableViewController, MPMediaPickerControllerDelegate
{
    // MARK: Constants.
    static let segueToSongGrapherKey: String = "toSongGrapher"
    
    var songs: [Song]!
    var chosenMediaItem: MPMediaItem?
    var mediaPicker: MPMediaPickerController?
    var spinner: UIActivityIndicatorView!
    //        let context: NSManagedObjectContext = CentralCode.getDBContext()
    var context: NSManagedObjectContext?
    
    @IBAction func addSong(_ sender: UIBarButtonItem)
    {
        self.mediaPicker = MPMediaPickerController(mediaTypes: MPMediaType.music)
        self.mediaPicker!.delegate = self
        self.mediaPicker!.allowsPickingMultipleItems = false
        self.mediaPicker!.showsCloudItems = true
        if let hasNavController = self.navigationController
        {
            hasNavController.present(self.mediaPicker!, animated: true, completion: nil)
        }
        else
        {
            CentralCode.showError(message: "The Navigation Controller is invalid!  BUILD AGAIN!", title: "Internal Error", onViewController: self)
        }
    }
    
    func loadSongs()
    {
        do
        {
            self.songs = try Song.getSongs(inContext: context!)
        }
        catch let err
        {
            CentralCode.showError(message: "Failed to read Song List! OS Error is: \(err.localizedDescription)", title: "Data Error", onViewController: self)
        }
        
    }
    
    func getId(fromSong: Song) -> UInt64
    {
        guard let backingId = fromSong.id, let trueId = UInt64(backingId)
            else
        {
            CentralCode.showError(message: "Failed to find the ID for a backing MPMediaItem!", title: "Table Data Error", onViewController: self)
            abort()
        }
        return trueId
    }
    
    // MARK: View Controller Life Cycle Methods.
    
    override func viewWillAppear(_ animated: Bool)
    {
        loadSongs()
        self.tableView.reloadData()
    }
    
    // MARK: UITableViewDataSource Delegate Methods.
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as? SongCell
            else
        {
            CentralCode.showError(message: "Failed to dequeue Song Cell!", title: "Table Cell Error", onViewController: self)
            abort()
        }
        guard let songs = self.songs
            else
        {
            CentralCode.showError(message: "Failed to acess backing Songs List!", title: "Table Data Error", onViewController: self)
            abort()
        }
        let currentSong = (songs[indexPath.row]) as Song
        let trueId = getId(fromSong: currentSong)
        guard let backingMediaItem = MPMediaWrapper.getSong(withId: trueId)
            else
        {
            CentralCode.showError(message: "Failed to get backing MPMediaItem!", title: "Table Data Error", onViewController: self)
            abort()
        }
        let size = cell.albumCover.bounds.size
        if let hasArtwork = backingMediaItem.artwork
        {
            cell.albumCover.image = hasArtwork.image(at: size)
        }
        cell.nwLabel.text = currentSong.album
        cell.swLabel.text = currentSong.artist
        cell.neLabel.text = currentSong.name
        if let pItems = currentSong.getPracticeItems()
        {
            cell.seLabel.text = "Practice Count: \(pItems.count)"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard let songs = self.songs
            else
        {
            CentralCode.showError(message: "Failed to get backing Song List while reporting how many rows in section!", title: "Table Data Error", onViewController: self)
            abort()
        }
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let currentSong = (self.songs![indexPath.row]) as Song
        let trueId = getId(fromSong: currentSong)
        guard let backingMediaItem = MPMediaWrapper.getSong(withId: trueId)
            else
        {
            CentralCode.showError(message: "Failed to get backing MPMediaItem!", title: "Table Data Error", onViewController: self)
            abort()
        }
        self.chosenMediaItem = backingMediaItem
        process(mediaItem: backingMediaItem, fromPicker: nil)
    }
    
    // MARK: View Transition Methods.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == SongsTVC.segueToSongGrapherKey, let nextVC = segue.destination as? SongGrapher, let chosenSong = self.chosenMediaItem
        {
            nextVC.context = self.context
            nextVC.songChosen = chosenSong
            let titlePart1 = (chosenSong.title != nil) ? chosenSong.title! : "Unknown"
            let titlePart2 = (chosenSong.albumArtist !=  nil) ? chosenSong.albumArtist! : ""
            let titlePart3 = (chosenSong.albumTitle != nil) ? chosenSong.albumTitle! : ""
            let artistAndAlbum = "Song:\(titlePart1) - Artist:\(titlePart2) - Album:\(titlePart3)"
            nextVC.title = "\(artistAndAlbum)"
        }
    }
    
    func process(mediaItem: MPMediaItem, fromPicker: MPMediaPickerController?)
    {
        if let hasChosenASong = self.chosenMediaItem
        {
            if mediaPicker != nil
            {
                mediaPicker!.dismiss(animated: true, completion: nil)
            }
            if MPMediaWrapper.isDRMProtected(theSongID: hasChosenASong.persistentID)
            {
                CentralCode.showError(message: "Sorry that song is protected by DRM!", title: "Song Security Error", onViewController: self)
                return
            }
            if MPMediaWrapper.isInCloud(theSongID: hasChosenASong.persistentID)
            {
                CentralCode.showError(message: "Sorry that song is in the cloud.  Please download it in the iTunes App and try again!", title: "Song Location Error", onViewController: self)
                return
            }
            guard let importCacheFileURL = BundleWrapper.getImportCacheFileURL(forSong: hasChosenASong)
                else
            {
                CentralCode.showError(message: "Failed to acquire a path for the temporary Import File!  Note: This file is not DRM protected so who knows why?", title: "Song Choice Error", onViewController: self)
                return
            }
            // Preceding code guarntees that the assetURL is not nil!
            let inputURL: URL = hasChosenASong.assetURL!
            do
            {
                if try Song.doesSongExist(inContext: context!, mpItem: hasChosenASong)
                {
                    self.performSegue(withIdentifier: SongsTVC.segueToSongGrapherKey, sender: self)
                }
                else
                {
                    let importGuy = MediaImport()
                    do
                    {
                        try importGuy.doImport(inputURL, output: importCacheFileURL, completionCode:
                        {
                            [weak self] (importGuy, error) in
                            if let strongSelf = self
                            {
                                if let hasError = error
                                {
                                    CentralCode.showError(message: "\(hasError.localizedDescription)", title: "Import Error", onViewController: strongSelf)
                                    return
                                }
                                if importGuy.status == AVAssetExportSessionStatus.completed
                                {
                                    if FileManager.default.fileExists(atPath: importCacheFileURL.path)
                                    {
                                        print("Before perform!")
                                        strongSelf.performSegue(withIdentifier: SongsTVC.segueToSongGrapherKey, sender: strongSelf)
                                        print("After perform!")
                                    }
                                    else
                                    {
                                        CentralCode.showError(message: "Import Status of music file is good but file was not found after copy?", title: "Import Error", onViewController: strongSelf)
                                    }
                                }
                                else
                                {
                                    switch importGuy.status
                                    {
                                    case AVAssetExportSessionStatus.cancelled:
                                        CentralCode.showError(message: "Import Status is not completed.  Status is Cancelled", title: "Import Error", onViewController: strongSelf)
                                    case AVAssetExportSessionStatus.exporting:
                                        CentralCode.showError(message: "Import Status is not completed.  Status is Exporting", title: "Import Error", onViewController: strongSelf)
                                    case AVAssetExportSessionStatus.failed:
                                        CentralCode.showError(message: "Import Status is not completed.  Status is Failed", title: "Import Error", onViewController: strongSelf)
                                    case AVAssetExportSessionStatus.unknown:
                                        CentralCode.showError(message: "Import Status is not completed.  Status is Unknown", title: "Import Error", onViewController: strongSelf)
                                    case AVAssetExportSessionStatus.waiting:
                                        CentralCode.showError(message: "Import Status is not completed.  Status is Waiting", title: "Import Error", onViewController: strongSelf)
                                    default:
                                        CentralCode.showError(message: "Import Status is not completed.  Status is Fucked!", title: "Import Error", onViewController: strongSelf)
                                    }
                                }
                            }
                        })
                    }
                    catch let error
                    {
                        var errorMessage: String
                        var errorTitle: String
                        switch error
                        {
                        case ImportErrors.badFileType(fileExtension: let errM):
                            errorMessage = "Cannot handle files of type \(errM)!"
                            errorTitle = "Song Choice Error"
                        case ImportErrors.cantKillTempFile(fileName: let errM):
                            errorMessage = "Cannot kill temp file \(errM)!"
                            errorTitle = "Temp File Error"
                        case ImportErrors.cantOpenDestinationFile(fileName: let errM):
                            errorMessage = "Cannot open destination file \(errM)!"
                            errorTitle = "Destination File Error"
                        case ImportErrors.cantOpenTempFile(fileName: let errM):
                            errorMessage = "Cannot open Temp file \(errM)!"
                            errorTitle = "Temp File Error"
                        case ImportErrors.compositionObjectFailure(failureReason: let errM):
                            errorMessage = "Cannot create Compostion Object: \(errM)!"
                            errorTitle = "Composition File Error"
                        case ImportErrors.exportSessionCanceled(reason: let errM):
                            errorMessage = "Export session was cancelled unexpectedly: \(errM)!"
                            errorTitle = "Export Session Error"
                        case ImportErrors.exportSessionFailed(reason: let errM):
                            errorMessage = "Export session was failed unexpectedly: \(errM)!"
                            errorTitle = "Export Session Error"
                        case ImportErrors.fileNotExportable(fileName: let errM):
                            errorMessage = "File \(errM) is not exportable!"
                            errorTitle = "Export File Error"
                        case ImportErrors.fileTypeNotSupported(fileExtension: let errM):
                            errorMessage = "File type \(errM) is not Supported!"
                            errorTitle = "File Type Error"
                        case ImportErrors.inputURLMissing:
                            errorMessage = "Input file parameter is missing!"
                            errorTitle = "Input File Error"
                        case ImportErrors.outputFileAlreadyExists:
                            errorMessage = "Output file already exists!"
                            errorTitle = "Output File Error"
                        case ImportErrors.outputURLMissing:
                            errorMessage = "Output file parameter is missing!"
                            errorTitle = "Output File Error"
                        case ImportErrors.sessionFailedToInit:
                            errorMessage = "Export session failed to Initialize!"
                            errorTitle = "Export Session Error"
                        default:
                            errorMessage = "Unknown ERRE!"
                            errorTitle = "Unknown Error"
                        }
                        CentralCode.runInMainThread {
                            CentralCode.showError(message: errorMessage, title: errorTitle, onViewController: self)
                        }
                    }
                }
            }
            catch let err
            {
                CentralCode.runInMainThread {
                    CentralCode.showError(message: err.localizedDescription, title: "Song Search Error", onViewController: self)
                }
            }
        }
    }
    
    // MARK: MPMediaPickerControllerDelegate Functions.
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection)
    {
        self.chosenMediaItem = mediaItemCollection.items[0]
        process(mediaItem: self.chosenMediaItem!, fromPicker: mediaPicker)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController)
    {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
}
