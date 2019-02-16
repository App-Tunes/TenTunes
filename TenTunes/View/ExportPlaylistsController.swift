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
    
    @IBOutlet var _trackLibrary: NSPathControl!
    
    @IBOutlet var _libraryDirectory: NSPathControl!
    @objc dynamic var libraryEnabled: Bool = false

    @IBOutlet var _destinationDirectory: NSPathControl!
    @objc dynamic var m3uEnabled: Bool = false

    @IBOutlet var _aliasDirectory: NSPathControl!
    @objc dynamic var aliasEnabled: Bool = false

    @IBOutlet var _rekordboxSelect: NSPopUpButton!
    var selectStubs = ActionStubs()
    
    @IBOutlet var _exportOnlySelected: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        _trackLibrary.url = Library.shared.mediaLocation.directory
        
        volumesChanged()
        
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(didMount(_:)), name: NSWorkspace.didMountNotification, object: nil)
        nc.addObserver(self, selector: #selector(didUnMount(_:)), name: NSWorkspace.didUnmountNotification, object: nil)
    }
    
    func volumesChanged() {
        _rekordboxSelect.removeAllItems()
        selectStubs.clear()
        
        _rekordboxSelect.menu?.addItem(NSMenuItem(title: "Select Rekordbox Device...", action: nil, keyEquivalent: ""))

        guard let mountedURLs = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [], options: []) else {
            return
        }

        for mountedURL in mountedURLs {
            let components = mountedURL.pathComponents
            
            guard components.count > 2 && components[1] == "Volumes" else {
                continue
            }
            
            let libraryURL = mountedURL.appendingPathComponent("Contents")
            
            guard FileManager.default.fileExists(atPath: libraryURL.path) else {
                continue
            }
            
            let item = NSMenuItem(title: components[2], action: nil, keyEquivalent: "")
            selectStubs.bind(item) { [unowned self] _ in
                self._trackLibrary.url = libraryURL
                
                let createMountedDirectory: ([String]) -> URL = {
                    let url = $0.reduce(into: mountedURL, {
                        $0 = $0.appendingPathComponent($1)
                    })
                    try! url.ensureIsDirectory()
                    return url
                }
                
                let tenTunes = ["Ten Tunes"]
                let exports = tenTunes + ["Exports"]
                
                self._libraryDirectory.url = createMountedDirectory(["Ten Tunes"])
                self.libraryEnabled = true
                
                self._destinationDirectory.url = createMountedDirectory(exports + ["M3U"])
                self.m3uEnabled = true
                
                self._aliasDirectory.url = createMountedDirectory(exports + ["Alias"])
                self.aliasEnabled = true
            }
            _rekordboxSelect.menu?.addItem(item)
        }
    }
    
    @IBAction func export(_ sender: Any) {
        var playlists: [Playlist]
        if _exportOnlySelected.state == .on {
            let selected = ViewController.shared.playlistController.selectedPlaylists.map { $0.1 }
            playlists = selected.flatten {
                ($0 as? PlaylistFolder)?.childrenList
            }
        }
        else {
            playlists = try! Library.shared.viewContext.fetch(Playlist.fetchRequest())
        }
        
        guard !playlists.isEmpty else {
            NSAlert.informational(title: "No Playlists Selected", text: "There are no playlists to export! Please make sure that you actually select some.")
            return
        }
        
        let exportTask = ExportPlaylists(tracksURL: _trackLibrary.url!, playlists: playlists)
        exportTask.libraryURL = libraryEnabled ? _libraryDirectory.url : nil
        exportTask.destinationURL = m3uEnabled ? _destinationDirectory.url : nil
        exportTask.aliasURL = aliasEnabled ? _aliasDirectory.url : nil

        ViewController.shared.tasker.enqueue(task: exportTask)
        
        NSAlert.informational(title: "Exporting Playlists", text: "\(playlists.count) playlists are being exported. You can check the progress in the task view.")
    }
    
    @objc func didMount(_ notification: NSNotification)  {
        self.volumesChanged()
    }
    @objc func didUnMount(_ notification: NSNotification)  {
        self.volumesChanged()
    }
}
