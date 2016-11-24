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
    
    var songs: [Song]?
    var chosenSong: MPMediaItem?
    var mediaPicker: MPMediaPickerController?
    var spinner: UIActivityIndicatorView!
    
    @IBAction func addSong(_ sender: UIBarButtonItem)
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
            CentralCode.showError(message: "The Navigation Controller is invalid!  BUILD AGAIN!", title: "Internal Error", onViewController: self)
        }
    }
    
    func loadSongs()
    {
        let context:    NSManagedObjectContext = CentralCode.getDBContext()
        do
        {
            self.songs = try Song.getSongs(inContext: context)
        }
        catch let err
        {
            CentralCode.showError(message: "Failed to read Song List! OS Error is: \(err.localizedDescription)", title: "Data Error", onViewController: self)
        }
    }
    
    func getId(fromSong: Song) -> UInt64
    {
        guard let backingId = fromSong.id
            else
        {
            CentralCode.showError(message: "Failed to find backing MPMediaItem!", title: "Table Data Error", onViewController: self)
            abort()
        }
        guard let trueId = UInt64(backingId)
            else
        {
            CentralCode.showError(message: "Failed to convert MPMediaItem Persisten ID!", title: "Table Data Error", onViewController: self)
            abort()
        }
        return trueId
    }
    
    override func viewDidLoad()
    {
        loadSongs()
    }
    
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
        let trueId = getId(fromSong: songs[indexPath.row])
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
        let currentSong = (songs[indexPath.row]) as Song
        cell.nwLabel.text = currentSong.album
        cell.swLabel.text = currentSong.artist
        cell.neLabel.text = currentSong.name
        cell.seLabel.text = "\(currentSong.getPracticeItems()?.count) - PI's"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
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
        self.chosenSong = backingMediaItem
        process(mediaItem: backingMediaItem, mediaPicker: nil)
    }
    
    // MARK: View Transition Methods.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == SongsTVC.segueToSongGrapherKey, let nextVC = segue.destination as? SongGrapher, let chosenSong = self.chosenSong
        {
            nextVC.songChosen = self.chosenSong
            let titlePart1 = (chosenSong.title != nil) ? chosenSong.title! : "Unknown"
            let titlePart2 = (chosenSong.albumArtist !=  nil) ? chosenSong.albumArtist! : ""
            let titlePart3 = (chosenSong.albumTitle != nil) ? chosenSong.albumTitle! : ""
            let artistAndAlbum = "Song:\(titlePart1) - Artist:\(titlePart2) - Album:\(titlePart3)"
            nextVC.title = "\(artistAndAlbum)"
        }
    }
    
    func process(mediaItem: MPMediaItem, mediaPicker: MPMediaPickerController?)
    {
        if let hasChosenASong = self.chosenSong
        {
            self.spinner = CentralCode.startSpinner(onView: self.view)
            guard let importCacheFileURL = BundleWrapper.getImportCacheFileURL(forSong: hasChosenASong)
                else
            {
                if mediaPicker != nil
                {
                    mediaPicker!.dismiss(animated: true, completion: nil)
                }
                if hasChosenASong.hasProtectedAsset == true
                {
                    CentralCode.showError(message: "Sorry that song is protected by DRM!", title: "Song Choice Error", onViewController: self)
                }
                else
                {
                    CentralCode.showError(message: "Failed to aquire a path for the temporary Import File!  Note: This file is not DRM protected so who knows why?", title: "Song Choice Error", onViewController: self)
                }
                CentralCode.stopSpinner(self.spinner)
                return
            }
            // Preceding code guarntees that the assetURL is not nil!
            let inputURL: URL = hasChosenASong.assetURL!
            if mediaPicker != nil
            {
                mediaPicker!.dismiss(animated: true, completion: nil)
            }
            let context = CentralCode.getDBContext()
            do
            {
                if try Song.doesSongExist(inContext: context, mpItem: hasChosenASong)
                {
                    CentralCode.stopSpinner(self.spinner)
                    self.performSegue(withIdentifier: SongChooser.segueToSongGrapherKey, sender: self)
                }
                else
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
                                        CentralCode.runInMainThread(code:
                                            {
                                                CentralCode.stopSpinner(strongSelf.spinner)
                                                strongSelf.performSegue(withIdentifier: SongChooser.segueToSongGrapherKey, sender: self)
                                        })
                                    }
                                    else
                                    {
                                        CentralCode.runInMainThread(code:
                                            {
                                                CentralCode.showError(message: "Import Status of music file is good but file was not found after copy?", title: "Import Error", onViewController: strongSelf)
                                                CentralCode.stopSpinner(strongSelf.spinner)
                                        })
                                    }
                                }
                                else
                                {
                                    CentralCode.runInMainThread(code:
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
                                            CentralCode.stopSpinner(strongSelf.spinner)
                                    })
                                }
                            }
                    })
                    
                }
            }
            catch let error
            {
                CentralCode.showError(message: error.localizedDescription, title: "Song Choice Error", onViewController: self)
                CentralCode.stopSpinner(self.spinner)
            }
            
        }
    }
    
    // MARK: MPMediaPickerControllerDelegate Functions.
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection)
    {
        let item = mediaItemCollection.items[0]
        self.chosenSong = item
        process(mediaItem: item, mediaPicker: mediaPicker)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController)
    {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
}
