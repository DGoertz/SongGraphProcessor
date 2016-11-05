//
//  BundleWrapper.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-10-21.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation
import  MediaPlayer

class BundleWrapper
{
    class func getDocumentsDirectory() -> String?
    {
        let dirs = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,FileManager.SearchPathDomainMask.allDomainsMask, true)
        if dirs.count > 0
        {
            return dirs[0] as String
        }
        return nil
    }
    
    class func getCacheDirectory() -> String?
    {
        let possibles = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if possibles.count > 0
        {
            return possibles[0] as String
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
    
    class func doesAudioGraphFileExist(forSong: MPMediaItem) -> Bool
    {
        if let songGraphFileName = BundleWrapper.getAudioGraphFileURL(forSong: forSong)
        {
            return FileManager.default.fileExists(atPath: songGraphFileName.path)
        }
        return false
    }
    
    class func doesImportCacheFileExist(forSong: MPMediaItem) -> Bool
    {
        if let importCacheFileName = BundleWrapper.getImportCacheFileURL(forSong: forSong)
        {
            return FileManager.default.fileExists(atPath: importCacheFileName.path)
        }
        return false
    }
    
    class func removeAudioGraphFileIfNeeded(forSong: MPMediaItem)
    {
        if BundleWrapper.doesAudioGraphFileExist(forSong: forSong)
        {
            do
            {
                if let audioGraphFile = BundleWrapper.getAudioGraphFileURL(forSong: forSong)
                {
                    try FileManager.default.removeItem(at: audioGraphFile)
                }
            }
            catch
            {
                print("Failed to remove the Audio Graph file!")
            }
        }
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
