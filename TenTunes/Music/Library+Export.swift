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
        
        performInBackground { mox in
            self.updateExports(in: mox)
            completion()
        }
        
        exportSemaphore.signalAfter(seconds: 60)
        
        return true
    }
    
    func exportURL(title: String?, directory: Bool = true) -> URL {
        let exportsDirectory = self.directory.appendingPathComponent("Exports", isDirectory: true)
        let url = title != nil ? exportsDirectory.appendingPathComponent(title!, isDirectory: true) : exportsDirectory
        try! FileManager.default.createDirectory(at: directory ? url : exportsDirectory, withIntermediateDirectories: true, attributes: nil)
        return url
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
    
    func writeM3UPlaylists(playlists: [Playlist], changed: Set<NSManagedObject>) {
        let m3uRelative = exportURL(title: "M3U (Relative)")
        let m3uAbsolute = exportURL(title: "M3U (Absolute)")
        
        // TODO Clean up old playlists
        for playlist in playlists where playlist.doesContain(changed) || playlist.tracksList.anyMatch { changed.contains($0) } {
            Library.writeM3U(playlist: playlist, to: m3uRelative.appendingPathComponent(playlist.name.asFileName + ".m3u", isDirectory: false), absolute: false)
            Library.writeM3U(playlist: playlist, to: m3uAbsolute.appendingPathComponent(playlist.name.asFileName + ".m3u", isDirectory: false), absolute: true)
        }
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
    
    func writeiTunesLibraryXML(tracks: [Track], playlists: [Playlist]) {
        var dict: [String: Any] = [:]
        
        dict["Major Version"] = 1
        dict["Minor Version"] = 1
        
        dict["Application Version"] = "12.7.3.46"
        dict["Date"] = NSDate()
        dict["Features"] = 5 // TODO? Wat is dis
        dict["Show Content Ratings"] = true
        dict["Library Persistent ID"] = "ABX" // TODO Hex String
        
        let to16Hex: (UUID) -> String = { $0.uuidString.replacingOccurrences(of: "-", with: "")[0...15] }
        
        let tracksDicts: [String: Any] = Dictionary(uniqueKeysWithValues: tracks.enumerated().map { (idx, track) in
            var trackDict: [String: Any] = [:]
            
            trackDict["Track ID"] = idx
            trackDict["Name"] = track.title
            trackDict["Artist"] = track.author
            trackDict["Album"] = track.album
            trackDict["Location"] = track.path
            trackDict["Genre"] = track.genre
            trackDict["BPM"] = track.bpm ?=> Int.init
            trackDict["Persistent ID"] = track.iTunesID ?? to16Hex(track.id) // TODO
            
            return (String(idx), trackDict)
        })
        dict["Tracks"] = tracksDicts
        
        let playlistPersistentID: (Playlist) -> String = { $0.iTunesID ?? to16Hex($0.id)  } // TODO
        
        let trackIDs: [Track: Int] = Dictionary(uniqueKeysWithValues: tracks.enumerated().map { (idx, track) in (track, idx) })
        let playlistsArray: [[String: Any]] = playlists.enumerated().map { tuple in
            let (idx, playlist) = tuple // TODO Destructure in param (later Swift)
            var playlistDict: [String: Any] = [:]
            
            playlistDict["Playlist ID"] = idx
            playlistDict["Name"] = playlist.name
            playlistDict["Playlist Persistent ID"] = playlistPersistentID(playlist)
            if playlist.parent != nil {
                playlistDict["Parent Persistent ID"] = playlistPersistentID(playlist.parent!)
            }
            
            var tracks = playlist.tracksList
            if playlist == masterPlaylist {
                tracks = allTracks.tracksList
                playlistDict["Master"] = true
                playlistDict["All Items"] = true
                playlistDict["Visible"] = false
            }
            
            playlistDict["Playlist Items"] = tracks.map { track in
                return ["Track ID": trackIDs[track]]
            }
            
            return playlistDict
        }
        dict["Playlists"] = playlistsArray
        
        dict["Music Folder"] = directory.appendingPathComponent("Media").absoluteString
        
        (dict as NSDictionary).write(toFile: exportURL(title: "iTunes Library.xml", directory: false).path, atomically: true)
    }
}
