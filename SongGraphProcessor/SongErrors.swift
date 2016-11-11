//
//  SongErrors.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-11-10.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation

enum SongErrors: Error
{
    case saveFailed(errorMessage: String)
    case selectFailed(errorMessage: String)
}
