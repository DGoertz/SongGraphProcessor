//
//  ImportErrors.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-10-21.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation

enum ImportErrors: Error
{
    case fileShouldNotExist(fileName: String)
    case badFileType(fileExtension: String)
    case inputURLMissing
    case outputURLMissing
    case sessionFailedToInit
    case cantKillTempFile(fileName: String)
    case cantOpenTempFile(fileName: String)
    case cantOpenDestinationFile(fileName: String)
}
