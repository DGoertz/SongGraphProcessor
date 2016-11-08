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
    case importCacheFileNotFound(errorMessage: String)
    case osLevelError(errorMessage: String)
    case sampleBufferCopyFailure
    case assetReaderFailure(errorMessage: String)
    case fontNotLoaded(errorMessage: String)
    case graphicsContextMissing(errorMessage: String)
    case faileToGetImageFromContext
}
