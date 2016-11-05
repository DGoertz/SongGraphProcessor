//
//  MediaImport.swift
//  SongGraphProcessor
//
//  Created by David Goertz on 2016-10-21.
//  Copyright © 2016 David Goertz. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class MediaImport
{
    // MARK: Constants.
    
    static let ERROR_DOMAIN:    String = "DavesDomain"
    static let BASE_ERROR_CODE: Int    = 9999
    static let IPOD_SCHEME:     String = "ipod-library"
    
    // MARK: Properties.
    var importSession: AVAssetExportSession?
    var errorMessage:  String?
    var errorCode:     Int?
    
    // MARK: iVars.
    var error:         NSError?
    {
        if let hasSession = importSession
        {
            if let errorMessage = errorMessage
            {
                if let errorCode = errorCode
                {
                    let errorDict: [AnyHashable: Any] = [NSLocalizedDescriptionKey : errorMessage ]
                    return NSError(domain: MediaImport.ERROR_DOMAIN, code: errorCode, userInfo: errorDict)
                }
                else
                {
                    let errorDict: [AnyHashable: Any] = [NSLocalizedDescriptionKey : errorMessage ]
                    return NSError(domain: MediaImport.ERROR_DOMAIN, code: MediaImport.BASE_ERROR_CODE, userInfo: errorDict)
                }
            }
            return hasSession.error as NSError?
        }
        return nil
    }
    
    var progress: Float
    {
        if let hasSession = importSession
        {
            return hasSession.progress
        }
        return 0
    }
    
    var status: AVAssetExportSessionStatus
    {
        if let hasSession = importSession
        {
            if let _ = error
            {
                return AVAssetExportSessionStatus.failed
            }
            return hasSession.status
        }
        return AVAssetExportSessionStatus.unknown
    }
    
    /**
     Takes care that parameters are valid before trying to do the actual import.
     
     - parameters:
     - input: should be an ipod music file in your phone or ipod.
     - output: is the file that you will be parsing into a graph.
     - completion code: code that should make use of the output file and graph it's contents.
     - throws:
     - input can't be nil.
     - output can't be nil.
     - the output file should not exist yet.
     */
    func doImport(_ input: URL?, output: URL?, completionCode: @escaping (MediaImport) -> Void ) throws -> Void
    {
        guard let goodInput = input
            else
        {
            self.errorMessage = "In startImport and the input URL is nil!"
            throw ImportErrors.inputURLMissing
        }
        guard let goodOutput = output
            else
        {
            self.errorMessage = "In startImport and the output URL is nil!"
            throw ImportErrors.outputURLMissing
        }
        guard MediaImport.isValidInputURL(goodInput)
            else
        {
            self.errorMessage = "In startImport and the input URL is pointing to a file with a bad extension!"
            throw ImportErrors.badFileType(fileExtension: goodInput.absoluteString)
        }
        guard !FileManager.default.fileExists(atPath: goodOutput.path)
            else
        {
            self.errorMessage = "In startImport and the output file already exists!"
            throw ImportErrors.fileShouldNotExist(fileName: goodOutput.path)
        }
        do
        {
            try completeImport(goodInput, output: goodOutput, completionCode: completionCode)
        }
        catch let error
        {
            self.errorMessage = "In startImport and the import failed!"
            throw error
        }
    }
    
    /**
     Spins up an import session and then depending on the type of input file type, tries to do the actual import.
     
     - parameters:
     - input: should be an ipod music file in your phone or ipod.
     - output: is the file that you will be parsing into a graph.
     - completion code: code that should make use of the output file and graph it's contents.
     - throws:
     - the import session must be creatable.
     */
    func completeImport(_ input: URL, output: URL, completionCode: @escaping (MediaImport) -> Void) throws -> Void
    {
        let options: [String : AnyObject]? = nil
        let asset = AVURLAsset(url: input, options: options)
        guard let haveSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
            else
        {
            throw ImportErrors.sessionFailedToInit
        }
        self.importSession = haveSession
        if input.pathExtension == "mp3"
        {
            do
            {
                try self.doMP3Import(output, completionCode: completionCode)
            }
            catch let error
            {
                throw error
            }
            return
        }
        else
        {
            haveSession.outputURL = output
            switch input.pathExtension
            {
            case "m4a":
                haveSession.outputFileType = AVFileTypeAppleM4A
            case "wav":
                haveSession.outputFileType = AVFileTypeWAVE
            case "aif":
                haveSession.outputFileType = AVFileTypeAIFC
            default:
                throw ImportErrors.badFileType(fileExtension: input.pathExtension)
            }
        }
        haveSession.exportAsynchronously(
            completionHandler: {
                () -> Void in
                completionCode(self)
        })
        return
    }
    
    /**
     Processes an MP3 file by importing it to a Movie file.
     - parameters:
     - destination: is the file that you will be parsing into a graph.
     - completion code: code that should make use of the output file and graph it's contents.
     - throws:
     - the old temporary movie file must be able to be cleaned out before proceeding.
     */
    func doMP3Import(_ destination: URL, completionCode: @escaping (MediaImport) -> Void) throws -> Void
    {
        let movieFileURL = destination.deletingPathExtension().appendingPathExtension("mov")
        let aFileManager = FileManager.default
        // Delete the temporary file in case it was left over from before.
        if FileManager.default.fileExists(atPath: movieFileURL.path)
        {
            do
            {
                try aFileManager.removeItem(at: movieFileURL)
            }
            catch
            {
                throw ImportErrors.cantKillTempFile(fileName: movieFileURL.absoluteString)
            }
        }
        if let hasSession  = self.importSession
        {
            hasSession.outputURL = movieFileURL
            hasSession.outputFileType = AVFileTypeQuickTimeMovie
            hasSession.exportAsynchronously(completionHandler:
                {
                self.processAsMovieFile(destination, completionCode: completionCode, movieFileName: movieFileURL)
            })
        }
    }
    
    /**
     If the import into a movie file failed then finish with the passed in completionCode.
     If file was sucessfully imported to a movie file then we copy that file to one
     we will be processing into a graph.
     - parameters:
     - destination: the final product, the file we will create a graphical image from.
     - completionCode: the code that will process the file into a graph.
     - movieFileName: the file that the import session brought out of the iPod library.
     
     */
    func processAsMovieFile(_ destination: URL, completionCode: (MediaImport) -> Void, movieFileName: URL) -> Void
    {
        // Import either worked asynchronously or it failed and is dropping to this code.
        // The import would have used the self.importSession member and its
        // various settings like: outputURL, outputFileType.
        if self.importSession?.status == AVAssetExportSessionStatus.failed
        {
            completionCode(self)
        }
        else if self.importSession?.status == AVAssetExportSessionStatus.cancelled
        {
            completionCode(self)
        }
        else
        {
            do
            {
                try self.extractFromQuicktimeMovie(fromMovieFile: movieFileName, to: destination)
            }
            catch ImportErrors.cantOpenTempFile(let fileName)
            {
                self.errorMessage = "extractQuicktimeMovie failed as cannot open temp file \(fileName)!"
                completionCode(self)
                return
            }
            catch ImportErrors.cantOpenDestinationFile(let fileName)
            {
                self.errorMessage = "extractQuicktimeMovie failed as cannot open destination file \(fileName)!"
                completionCode(self)
                return
            }
            catch let error as NSError
            {
                self.errorMessage = error.localizedDescription
                self.errorCode = error.code
            }
            do
            {
                try FileManager.default.removeItem(at: movieFileName)
            }
            catch
            {
                self.errorMessage = "extractQuicktimeMovie failed as can't kill temp file \(movieFileName)"
                completionCode(self)
                return
            }
            completionCode(self)
        }
    }
    
    /**
     Extract data out of the Quick Time Movie file. All we need is the portion labeled
     'mdat'.
     - parameters:
        - fromMovieFile: the URL of the movie file to extract the portion from.
        - to: the destination URL that will hold the file to be processed into a song graph.
     - throws:
        - the input movie file must open properly for read access.
        - the ouput file should open properly for write access.
     */
    func extractFromQuicktimeMovie(fromMovieFile: URL, to: URL) throws -> Void
    {
        var movieFile: UnsafeMutablePointer<FILE>? = fopen(fromMovieFile.path.cString(using: String.Encoding.utf8)!, "r")
        guard movieFile != nil
            else
        {
            throw ImportErrors.cantOpenTempFile(fileName: fromMovieFile.path)
        }
        var atom_size: UnsafeMutablePointer<ULONG> = UnsafeMutablePointer.allocate(capacity: 1); defer{atom_size.deallocate(capacity: 1)}
        // We will read 4 bytes but set aside 5. The last will default to 0x00.
        // This allows us to us String.fromCString to convert it to a Swift String.
        var atom_name: UnsafeMutablePointer<CChar> = UnsafeMutablePointer.allocate(capacity: 5);defer {atom_name.deallocate(capacity: 5)}
        while (true)
        {
            // Detect END-OF-FILE!
            if (feof(movieFile) > 0)
            {
                break
            }
            // The next 4 bytes tell us the size of the next data packet.
            fread(atom_size, 4, 1, movieFile)
            
            // The next 4 bytes tell us the type of data packet that it is.
            fread(atom_name, 4, 1, movieFile)
            
            // Flip bytes to adjust for Network or Host byte ordering / Big or Little Endian.
            atom_size.pointee = CFSwapInt32HostToBig(atom_size.pointee)
            
            // We will use a 1 K buffer area.
            let bufferSize: Int = 1024 * 100
            
            // Check for an 'mdat' data packet.
            // Seems this is the only one we will process, so once we have it,
            // we process it and get out!
            let realName = String(cString: atom_name)
            if realName == "mdat"
            {
                // Open the Destination file.
                var destination: UnsafeMutablePointer<FILE>? = fopen(to.path.cString(using: String.Encoding.utf8)!, "w")
                if destination == nil
                {
                    fclose(movieFile);
                    throw ImportErrors.cantOpenDestinationFile(fileName: to.path)
                }
                var buf: UnsafeMutablePointer<CUnsignedChar> = UnsafeMutablePointer.allocate(capacity: bufferSize); defer {buf.deallocate(capacity: bufferSize)}
                
                // Quicktime atom size field includes the 8 bytes of the header itself.
                atom_size.pointee -= 8
                // So loop until we have read the entire Atom.
                while (atom_size.pointee != 0)
                {
                    // We try to read a full buffer at a time until we are near the end.
                    let read_size = (ULONG(bufferSize) < atom_size.pointee) ? ULONG(bufferSize) : atom_size.pointee
                    // Read and Write the bytes being processed.
                    if (fread(buf, Int(read_size), 1, movieFile) == 1)
                    {
                        fwrite(buf, Int(read_size), 1, destination);
                    }
                    // Adjust to keep up with how many bytes we have left to read.
                    atom_size.pointee = (ULONG(atom_size.pointee) - read_size)
                }
                // Processing is done so close the Source and Destination files.
                fclose(destination);
                fclose(movieFile);
                
                // We're DONE!
                return
            }
            // So we are skipping through data packets that are not labeled 'mdat'
            // If the next Atom Size is 0 this means we are at the end of the file.
            // Since we got here we can assume we did not process an MDAT chunk and therefore are DONE processing!
            if (atom_size.pointee == 0)
            {
                break
            }
            // We need to fast forward to the next chunk of data and check if it is an 'mdat' Atom.
            fseek(movieFile, MediaImport.toInt(atom_size.pointee), SEEK_CUR);
        }
        fclose(movieFile)
    }
    
    // MARK: Class Methods.
    
    /**
     The input URL must be for an ipod library resource and one of the file types:
     mp3, aif, m4a or wav
     - parameters:
     - inputURL the input file located in the ipod library.
     */
    class func isValidInputURL(_ inputURL: URL?) -> Bool
    {
        guard let url = inputURL
            else
        {
            return false
        }
        guard url.scheme == IPOD_SCHEME
            else
        {
            return false
        }
        return url.pathExtension == "mp3" || url.pathExtension == "aif" || url.pathExtension == "m4a" || url.pathExtension == "wav"
    }
    
    /**
     Convert an unsigned int to an int by chopping off the top bit.
     - parameters:
     - uInt the unsigned int to be converted.
     */
    class func toInt(_ uInt: UInt32) -> Int
    {
        return Int(uInt & 0x7FFF)
    }
}
