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
        guard _exportsRequireUpdate, exportSemaphore.acquireNow() else {
            return false
        }
        
        performInBackground { mox in
            self.updateExports(in: mox)
            completion()
        }
        
        return true
    }
    
    func exportDirectory(title: String) -> URL {
        let exportsDirectory = directory.appendingPathComponent("Exports", isDirectory: true)
        let url = exportsDirectory.appendingPathComponent(title, isDirectory: true)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }
    
    func updateExports(in mox: NSManagedObjectContext) {
        let tracks: [Track] = try! mox.fetch(Track.fetchRequest())
        // TODO Sort playlist by their parent / child tree
        let playlists: [Playlist] = try! mox.fetch(Playlist.fetchRequest())
        
        let m3uRelative = exportDirectory(title: "M3U (Relative)")
        let m3uAbsolute = exportDirectory(title: "M3U (Absolute)")
        
        for playlist in playlists {
            Library.writeM3U(playlist: playlist, to: m3uRelative.appendingPathComponent(playlist.name.asFileName + ".m3u", isDirectory: false), absolute: false)
            Library.writeM3U(playlist: playlist, to: m3uAbsolute.appendingPathComponent(playlist.name.asFileName + ".m3u", isDirectory: false), absolute: true)
        }
        
        _exportsRequireUpdate = false
        // Set this after fetching so no changes remain unexported
        
        exportSemaphore.signal()
    }
    
    static func writeM3U(playlist: Playlist, to: URL, absolute: Bool) {
        let tracks: [String] = playlist.tracksList.map { track in
            let info = "#EXTINF:\(track.durationSeconds ?? 0),\(track.rAuthor) - \(track.rTitle)"
            
            // TODO Put in path whether it exists or not
            let url = track.url ?? URL(fileURLWithPath: "unknown")
            
            return info + "\n" + (absolute ? url.path : (url.relativePath(from: to) ?? url.path))
        }
        let contents = "#EXTM3U\n" + tracks.joined(separator: "\n")
        
        try! contents.write(to: to, atomically: true, encoding: .utf8)
    }
}
