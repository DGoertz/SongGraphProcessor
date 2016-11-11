//
//  Song.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-11-10.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MediaPlayer

extension Song
{
    class func buildIdRequest(forMpItem: MPMediaItem) -> NSFetchRequest<Song>
    {
        let request: NSFetchRequest<Song> = Song.fetchRequest()
        let id = NSNumber(value: forMpItem.persistentID)
        request.predicate = NSPredicate(format: "id == %@", id)
        return request
    }
    
    class func doesSongExist(inContext: NSManagedObjectContext, mpItem: MPMediaItem) -> Bool
    {
        do
        {
            let results = try inContext.fetch(Song.buildIdRequest(forMpItem: mpItem))
            return results.count > 0
        }
        catch
        {
            return false
        }
    }
    
    class func getSong(inContext: NSManagedObjectContext, mpItem: MPMediaItem) throws -> Song?
    {
        do
        {
            let results = try inContext.fetch(Song.buildIdRequest(forMpItem: mpItem))
            if results.count > 0
            {
                return results[0]
            }
            return nil
        }
        catch let error
        {
            throw SongErrors.saveFailed(errorMessage: "Save of updated Song failed.  OS Error is: \(error.localizedDescription)")
        }
    }
    
    class func listSongs(inContext: NSManagedObjectContext) -> [Song]?
    {
        let request: NSFetchRequest<Song> = Song.fetchRequest()
        do
        {
            return try inContext.fetch(request)
        }
        catch
        {
            return nil
        }
    }
    
    class func addSong(toContext: NSManagedObjectContext, mpItem: MPMediaItem, graph: Data)
    {
        let newSong = Song(context: toContext)
        newSong.id = "\(mpItem.persistentID)"
        newSong.name = mpItem.title
        newSong.album = mpItem.albumTitle
        newSong.artist = mpItem.artist
        newSong.graph = graph as NSData?
    }
    
    class func updateSongGraph(inContext: NSManagedObjectContext, mpItem: MPMediaItem, graph: Data) throws -> Void
    {
        do
        {
            let results = try inContext.fetch(Song.buildIdRequest(forMpItem: mpItem))
            if results.count > 0
            {
                results[0].graph = graph as NSData?
            }
        }
        catch let error
        {
            throw SongErrors.saveFailed(errorMessage: "Selecting a Song for update failed.  OS Error is: \(error.localizedDescription)")
        }
    }
}
