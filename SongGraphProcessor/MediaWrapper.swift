//
//  MediaWrapper.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-10-21.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation
import MediaPlayer

class MPMediaWrapper
{
    final class func getSongs(forArtist artist: String) -> [MPMediaItem]?
    {
        var matchingSongs: [MPMediaItem] = [MPMediaItem]()
        let query: MPMediaQuery = MPMediaQuery()
        let artistPredicate = MPMediaPropertyPredicate(value: artist, forProperty:MPMediaItemPropertyAlbumArtist)
        query.addFilterPredicate(artistPredicate)
        if let results = query.items
        {
            for aSong in results
            {
                matchingSongs.append(aSong)
            }
        }
        return matchingSongs
    }
    
    final class func getSongs(forAlbum album: String) -> [MPMediaItem]?
    {
        var matchingSongs: [MPMediaItem] = [MPMediaItem]()
        let query: MPMediaQuery = MPMediaQuery()
        let albumPredicate = MPMediaPropertyPredicate(value: album, forProperty:MPMediaItemPropertyAlbumTitle)
        query.addFilterPredicate(albumPredicate)
        if let results = query.items
        {
            for aSong in results
            {
                matchingSongs.append(aSong)
            }
        }
        return matchingSongs
    }
    
    final class func getSong(withId: MPMediaEntityPersistentID) -> MPMediaItem?
    {
        let query: MPMediaQuery = MPMediaQuery()
        let songPredicate = MPMediaPropertyPredicate(value: withId, forProperty:MPMediaItemPropertyPersistentID)
        query.addFilterPredicate(songPredicate)
        if let results = query.items
        {
            return results[0]
        }
        return nil
    }
    
    final class func isInCloud(theSongID: MPMediaEntityPersistentID) -> Bool
    {
        let query: MPMediaQuery = MPMediaQuery()
        let songIDPredicate = MPMediaPropertyPredicate(value: theSongID, forProperty:MPMediaItemPropertyPersistentID)
        let isInCloudPredicate = MPMediaPropertyPredicate(value: true, forProperty:MPMediaItemPropertyIsCloudItem)
        query.addFilterPredicate(songIDPredicate)
        query.addFilterPredicate(isInCloudPredicate)
        if let results = query.items
        {
            let firstEntry = results.first
            return firstEntry != nil
        }
        return false
    }
    
    final class func isDRMProtected(theSongID: MPMediaEntityPersistentID) -> Bool
    {
        let query: MPMediaQuery = MPMediaQuery()
        let songIDPredicate = MPMediaPropertyPredicate(value: theSongID, forProperty:MPMediaItemPropertyPersistentID)
        query.addFilterPredicate(songIDPredicate)
        if let results = query.items
        {
            let firstEntry = results.first
            return firstEntry != nil && firstEntry!.hasProtectedAsset
        }
        return false
    }
}









