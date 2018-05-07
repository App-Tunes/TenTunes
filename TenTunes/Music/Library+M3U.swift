//
//  Library+M3U.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library {
    func writeM3UPlaylists(playlists: [Playlist], changed: Set<NSManagedObjectID>) {
        let m3uRelative = exportURL(title: "M3U (Relative)")
        let m3uAbsolute = exportURL(title: "M3U (Absolute)")
        
        // TODO Clean up old playlists
        for playlist in playlists where changed.contains(playlist.objectID) || playlist.tracksList.anyMatch { changed.contains($0.objectID) } {
            let filename = playlist.name.asFileName + ".m3u"
            var relative = m3uRelative
            var absolute = m3uAbsolute

            for component in Library.shared.path(of: playlist).dropLast().dropFirst() {
                relative = relative.appendingPathComponent(component.name.asFileName)
                absolute = absolute.appendingPathComponent(component.name.asFileName)
            }
            
            Library.writeM3U(playlist: playlist, to: relative.appendingPathComponent(filename, isDirectory: false), absolute: false)
            Library.writeM3U(playlist: playlist, to: absolute.appendingPathComponent(filename, isDirectory: false), absolute: true)
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
        
        try! to.ensurePath()
        try! contents.write(to: to, atomically: true, encoding: .utf8)
    }
}
