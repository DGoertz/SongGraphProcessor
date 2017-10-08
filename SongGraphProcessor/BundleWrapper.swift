//
//  BundleWrapper.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-10-21.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation
import  MediaPlayer
import CoreData

class BundleWrapper
{
    class func getDocumentsDirectory() -> String?
    {
        let dirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if dirs.count > 0
        {
            return dirs[0].absoluteString
        }
        return nil
    }
    
    class func getCacheDirectory() -> String?
    {
        let possibles = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let hasOne = possibles[0].absoluteString
        if hasOne.count > 0
        {
            return hasOne
        }
        return nil
    }
    
    class func getAudioGraphFileURL(forSong: MPMediaItem) -> URL?
    {
        if let cachePath = BundleWrapper.getCacheDirectory()
        {
            let graphFileName = BundleWrapper.getAudioGraphFileName(forSong: forSong)
            return URL(fileURLWithPath: cachePath).appendingPathComponent(graphFileName)
        }
        return nil
    }
    
    class func getExtention(forSong: MPMediaItem) -> String?
    {
        return forSong.assetURL?.pathExtension
    }
    
    class func getImportCacheFileURL(forSong: MPMediaItem) -> URL?
    {
        if let cachePath = BundleWrapper.getCacheDirectory(), let assetURL = forSong.assetURL
        {
            var fileName: String
            if let title = forSong.title
            {
                fileName = "\(title)-\(forSong.persistentID).\(assetURL.pathExtension)"
            }
            else
            {
                fileName = "Null_Title-\(forSong.persistentID).\(assetURL.pathExtension)"
            }
            return URL(fileURLWithPath: cachePath).appendingPathComponent(fileName)
        }
        return nil
    }
    
    class func getAudioGraphFileName(forSong: MPMediaItem) -> String
    {
        if let title = forSong.title
        {
            return "\(title)-\(forSong.persistentID).png"
        }
        return "Null_Title-\(forSong.persistentID).png"
    }
    
    class func doesAudioGraphExist(inContext: NSManagedObjectContext, forSong: MPMediaItem) throws -> Bool
    {
        do
        {            
            return try Song.doesSongExist(inContext: inContext, mpItem: forSong)
        }
        catch let err
        {
            throw err
        }
    }
    
    class func doesImportCacheFileExist(forSong: MPMediaItem) -> Bool
    {
        if let importCacheFileName = BundleWrapper.getImportCacheFileURL(forSong: forSong)
        {
            return FileManager.default.fileExists(atPath: importCacheFileName.path)
        }
        return false
    }
    
    class func removeImportCacheFileIfNeeded(forSong: MPMediaItem)
    {
        if BundleWrapper.doesImportCacheFileExist(forSong: forSong)
        {
            do
            {
                if let importCacheFile = BundleWrapper.getImportCacheFileURL(forSong: forSong)
                {
                    try FileManager.default.removeItem(at: importCacheFile)
                }
            }
            catch
            {
                print("Failed to remove the Audio Graph file!")
            }
        }
    }
}
