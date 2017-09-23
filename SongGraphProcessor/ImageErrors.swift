// Currently NOT being used since I could not get synchronized code
// in avAsset.loadValuesAsynchronously to throw exceptions.
// This is because I cannot change the signiture of the closure
// that that object wants to run as it's completion code.
// It's signiture is: (() -> Swift.Void)? and trying to change it
// to (() throws -> Swift.Void)? gives an error. 
//
//  ImageErrors.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-11-07.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation
enum UIImageErrors: Error
{
    case importCacheFileURLNotFound(errorMessage: String)
    case osLevelError(errorMessage: String)
    case sampleBufferCopyFailure
    case assetReaderFailure(errorMessage: String)
    //case fontNotLoaded(errorMessage: String)
    case graphicsContextMissing(errorMessage: String)
    case failedToGetImageFromContext(errorMessage: String)
    case imageNotObtainedFromContext
    case imageIsNotCGImage
    case failedToLoadFont(errorMessage: String)
}
