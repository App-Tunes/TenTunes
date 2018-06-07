//
//  ExportPlaylistsController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 05.06.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import AudioKit

class ExportPlaylistsController: NSWindowController {
    
    static let maxReadLength: AVAudioFramePosition = 100000

    @IBOutlet var _trackLibrary: NSPathControl!
    @IBOutlet var _destinationDirectory: NSPathControl!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        _trackLibrary.url = Library.shared.mediaLocation.directory
    }
    
    @IBAction func export(_ sender: Any) {
        let playlists = ViewController.shared.playlistController.selectedPlaylists.map { $0.1 }
//        let playlists: [Playlist] = try! Library.shared.viewContext.fetch(Playlist.fetchRequest())

        let toHash: (URL) -> Data? = {
            guard let file = try? AKAudioFile(forReading: $0) else {
                print("Failed to create audio file for \($0)")
                return nil
            }
            
            let readLength = AVAudioFrameCount(min(ExportPlaylistsController.maxReadLength, file.length))
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                          frameCapacity: readLength)
            
            do {
                try file.read(into: buffer!, frameCount: readLength)
            } catch let error as NSError {
                print("error cannot readIntBuffer, Error: \(error)")
            }
            
            return buffer!.withUnsafePointer(block: Hash.md5)
        }
        
        var src: [Data: URL] = [:]
        let dst: LazyMap<URL, Data?> = LazyMap(toHash)

        let libraryURL = _trackLibrary.url!
        let enumerator = FileManager.default.enumerator(at: libraryURL,
                                                        includingPropertiesForKeys: [ .isRegularFileKey ],
                                                        options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                            print("directoryEnumerator error at \(url): ", error)
                                                            return true
        })!
        
        var srcFound = 0
        var srcFailed = 0
        
        for case let url as URL in enumerator {
            let isRegularFile = try? url.resourceValues(forKeys: [ .isRegularFileKey ]).isRegularFile!
            if isRegularFile ?? false {
                if let md5 = toHash(url) {
                    if let existing = src[md5] {
                        print("Hash collision between urls \(url) and \(existing)")
                    }
                    
                    src[md5] = url
                    srcFound += 1
                    
                    if srcFound % 100 == 0 {
                        print("Found \(srcFound)")
                    }
                }
                else {
                    srcFailed += 1
                }
            }
        }
        
        if srcFailed > 0 {
            print("Failed sources: \(srcFailed)")
        }

        Library.writeRemoteM3UPlaylists(playlists, to: _destinationDirectory.url!, pathMapper: {
            guard let url = $0.url, let hash = dst[url] else {
                return nil
            }
            
            return src[hash]
        })
        
        // TODO Alert if some files were missing
    }
}
