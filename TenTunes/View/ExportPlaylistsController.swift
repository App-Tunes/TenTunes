//
//  ExportPlaylistsController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 05.06.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import AudioKit

class ExportPlaylistsController: NSWindowController, USBWatcherDelegate {
    
    static let maxReadLength: AVAudioFramePosition = 100000

    @IBOutlet var _trackLibrary: NSPathControl!
    @IBOutlet var _destinationDirectory: NSPathControl!
    
    @IBOutlet var _rekordboxSelect: NSPopUpButton!
    var selectStubs = ActionStubs()
    
    var usbWatcher: USBWatcher!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        _trackLibrary.url = Library.shared.mediaLocation.directory
        
        usbWatcher = USBWatcher(delegate: self)
        volumesChanged()
    }
    
    func volumesChanged() {
        _rekordboxSelect.removeAllItems()
        selectStubs.clear()
        
        _rekordboxSelect.menu?.addItem(NSMenuItem(title: "Select Rekordbox Device...", action: nil, keyEquivalent: ""))

        let paths = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [], options: [])
        if let urls = paths {
            for url in urls {
                let components = url.pathComponents
                if components.count > 2 && components[1] == "Volumes"
                {
                    let libraryURL = url.appendingPathComponent("Contents")
                    let playlistsURL = url.appendingPathComponent("Playlists")

                    if FileManager.default.fileExists(atPath: libraryURL.path) {
                        let item = NSMenuItem(title: components[2], action: nil, keyEquivalent: "")
                        selectStubs.bind(item) { [unowned self] _ in
                            self._trackLibrary.url = libraryURL
                            try! playlistsURL.ensureDirectory()
                            self._destinationDirectory.url = playlistsURL
                        }
                        _rekordboxSelect.menu?.addItem(item)
                    }
                }
            }
        }
    }
    
    @IBAction func export(_ sender: Any) {
        let selected = ViewController.shared.playlistController.selectedPlaylists.map { $0.1 }
        let playlists = selected.flatten {
            if let group = $0 as? PlaylistFolder {
                return group.childrenList
            }
            return nil
        }
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

        Library.writeRemoteM3UPlaylists(playlists, to: _destinationDirectory.url!) { (track, dest) in
            guard let url = track.url, let hash = dst[url] else {
                return nil
            }
            
            return src[hash]?.relativePath(from: libraryURL)
        }
        
        // TODO Alert if some files were missing
    }
    
    func deviceAdded(_ device: io_object_t) {
        volumesChanged()
    }
    
    func deviceRemoved(_ device: io_object_t) {
        volumesChanged()
    }
}
