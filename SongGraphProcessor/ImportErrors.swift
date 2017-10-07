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
    case compositionObjectFailure(failureReason: String)
    case fileNotExportable(fileName: String)
    case exportSessionFailed(reason: String)
    case exportSessionCanceled(reason: String)
    case badFileType(fileExtension: String)
    case fileTypeNotSupported(fileExtension: String)
    case outputFileAlreadyExists
    case inputURLMissing
    case outputURLMissing
    case sessionFailedToInit
    case cantKillTempFile(fileName: String)
    case cantOpenTempFile(fileName: String)
    case cantOpenDestinationFile(fileName: String)
}
