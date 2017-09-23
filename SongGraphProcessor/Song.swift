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
    final class func buildRequestFromMediaID(forMpItem: MPMediaItem) -> NSFetchRequest<Song>
    {
        let request: NSFetchRequest<Song> = Song.fetchRequest()
        let id = NSNumber(value: forMpItem.persistentID)
        request.predicate = NSPredicate(format: "id == %@", id)
        return request
    }
    
    final class func doesSongExist(inContext: NSManagedObjectContext, mpItem: MPMediaItem) throws -> Bool
    {
        do
        {
            let results = try inContext.fetch(Song.buildRequestFromMediaID(forMpItem: mpItem))
            return results.count > 0
        }
        catch let err
        {
            throw SongErrors.selectFailed(errorMessage: "Fetch of Song  in \(#function)  failed.  OS Error is: \(err.localizedDescription)")
        }
    }
    
    final class func getSong(inContext: NSManagedObjectContext, mpItem: MPMediaItem) throws -> Song?
    {
        do
        {
            let results = try inContext.fetch(Song.buildRequestFromMediaID(forMpItem: mpItem))
            if results.count > 1
            {
                throw SongErrors.idIsNotUnique
            }
            if results.count == 1
            {
                return results[0]
            }
            return nil
        }
        catch let err
        {
            throw SongErrors.selectFailed(errorMessage: "Fetch of Song  in \(#function) failed.  OS Error is: \(err.localizedDescription)")
        }
    }
    
    final class func getSongs(inContext: NSManagedObjectContext) throws -> [Song]?
    {
        let request: NSFetchRequest<Song> = Song.fetchRequest()
        do
        {
            return try inContext.fetch(request)
        }
        catch let err
        {
            throw SongErrors.selectFailed(errorMessage: "Fetching a list of Songs  in \(#function) failed.  OS Error is: \(err.localizedDescription)")
        }
    }
    
    final class func buildSongFromMediaItem(toContext: NSManagedObjectContext, mpItem: MPMediaItem, graph: Data) -> Song
    {
        let newSong = Song(context: toContext)
        newSong.id = "\(mpItem.persistentID)"
        newSong.name = mpItem.title
        newSong.album = mpItem.albumTitle
        newSong.artist = mpItem.artist
        newSong.graph = graph
        return newSong
    }
    
    final class func updateSongGraph(inContext: NSManagedObjectContext, mpItem: MPMediaItem, graph: Data) throws -> Song?
    {
        do
        {
            let results = try inContext.fetch(Song.buildRequestFromMediaID(forMpItem: mpItem))
            if results.count > 1
            {
                throw SongErrors.idIsNotUnique
            }
            if results.count == 1
            {
                results[0].graph = graph
                return results[0]
            }
        }
        catch let error
        {
            throw SongErrors.selectFailed(errorMessage: "Fetch of Song  in \(#function) failed.  OS Error is: \(error.localizedDescription)")
        }
        return nil
    }
    
    // Don't know if this is needed but the code auto-generated creates - for a to-many
    // relationship - something called an NSSet and not an NSSet<PracticeItem>.
    // In this function I return to you something actually useful.
    func getPracticeItems() -> [PracticeItem]?
    {
        guard let hasPractices = self.practices else {
            return nil
        }
        // Alternate code to test whether I have to parse through all elements or NOT!
        return hasPractices.allObjects as? [PracticeItem]
    }
}
