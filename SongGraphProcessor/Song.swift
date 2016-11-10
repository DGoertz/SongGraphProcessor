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
    class func doesSongExist(inContext: NSManagedObjectContext, mpItem: MPMediaItem) -> Bool
    {
        let request: NSFetchRequest<Song> = Song.fetchRequest()
        request.predicate = NSPredicate(format: "id == %i", mpItem.persistentID)
        do
        {
            let results = try inContext.fetch(request)
            return results.count > 0
        }
        catch
        {
            return false
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
}
