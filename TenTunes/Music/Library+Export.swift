//
//  Library+Export.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library {
    func startExport(completion: @escaping () -> Swift.Void) -> Bool {
        guard _exportChanged.count > 0, exportSemaphore.acquireNow() else {
            return false
        }
        
        performBackgroundTask { mox in
            self.updateExports(in: mox)
            completion()
        }
        
        exportSemaphore.signalAfter(seconds: 60)
        
        return true
    }
    
    func exportURL(title: String?, directory: Bool = true) -> URL {
        let exportsDirectory = self.directory.appendingPathComponent("Exports", isDirectory: true)
        return title != nil ? exportsDirectory.appendingPathComponent(title!, isDirectory: true) : exportsDirectory
    }
    
    func updateExports(in mox: NSManagedObjectContext) {
        let changed = _exportChanged
        _exportChanged = Set()

        let tracks: [Track] = try! mox.fetch(Track.fetchRequest())
        // TODO Sort playlist by their parent / child tree
        let playlists: [Playlist] = try! mox.fetch(Playlist.fetchRequest())
        
        writeM3UPlaylists(playlists: playlists, changed: changed)
        writeiTunesLibraryXML(tracks: tracks, playlists: playlists)
    }        
}
