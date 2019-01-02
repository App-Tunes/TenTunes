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
    @IBOutlet var _aliasDirectory: NSPathControl!
    
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

        let paths = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [], options: [])
        if let urls = paths {
            for url in urls {
                let components = url.pathComponents
                if components.count > 2 && components[1] == "Volumes"
                {
                    let libraryURL = url.appendingPathComponent("Contents")

                    if FileManager.default.fileExists(atPath: libraryURL.path) {
                        let item = NSMenuItem(title: components[2], action: nil, keyEquivalent: "")
                        selectStubs.bind(item) { [unowned self] _ in
                            self._trackLibrary.url = libraryURL

                            let playlistsURL = url.appendingPathComponent("Playlists")
                            try! playlistsURL.ensureIsDirectory()
                            self._destinationDirectory.url = playlistsURL

                            let aliasURL = url.appendingPathComponent("Playlists - Alias")
                            try! aliasURL.ensureIsDirectory()
                            self._aliasDirectory.url = aliasURL
                        }
                        _rekordboxSelect.menu?.addItem(item)
                    }
                }
            }
        }
    }
    
    @IBAction func export(_ sender: Any) {
        var playlists: [Playlist]
        if _exportOnlySelected.state == .on {
            let selected = ViewController.shared.playlistController.selectedPlaylists.map { $0.1 }
            playlists = selected.flatten {
                if let group = $0 as? PlaylistFolder {
                    return group.childrenList
                }
                return nil
            }
        }
        else {
            playlists = try! Library.shared.viewContext.fetch(Playlist.fetchRequest())
        }
        
        guard !playlists.isEmpty else {
            NSAlert.informational(title: "No Playlists Selected", text: "There are no playlists to export! Please make sure that you actually select some.")
            return
        }
        
        ViewController.shared.tasker.enqueue(task: ExportPlaylists(libraryURL: _trackLibrary.url!, playlists: playlists, destinationURL: _destinationDirectory.url!, aliasURL: _aliasDirectory.url!))
        
        NSAlert.informational(title: "Exporting Playlists", text: "\(playlists.count) playlists are being exported. You can check the progress in the task view.")
    }
    
    @objc func didMount(_ notification: NSNotification)  {
        self.volumesChanged()
    }
    @objc func didUnMount(_ notification: NSNotification)  {
        self.volumesChanged()
    }
}
