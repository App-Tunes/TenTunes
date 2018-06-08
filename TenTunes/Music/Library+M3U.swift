//
//  Library+M3U.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library {
    func writeM3UPlaylists(playlists: [Playlist], changed: Set<NSManagedObjectID>?) {
        Library.iterate(playlists: playlists, changed: changed, in: exportURL(title: "M3U (Relative)")) { (url, playlist) in
            let filename = playlist.name.asFileName + ".m3u"
            Library.writeM3U(playlist: playlist, to: url.appendingPathComponent(filename), absolute: false)
        }

        Library.iterate(playlists: playlists, changed: changed, in: exportURL(title: "M3U (Absolute)")) { (url, playlist) in
            let filename = playlist.name.asFileName + ".m3u"
            Library.writeM3U(playlist: playlist, to: url.appendingPathComponent(filename), absolute: true)
        }
    }
    
    static func writeRemoteM3UPlaylists(_ playlists: [Playlist], to: URL, pathMapper: @escaping (Track) -> URL?) {
        Library.iterate(playlists: playlists, changed: nil, in: to) { (url, playlist) in
            let filename = playlist.name.asFileName + ".m3u"
            Library.writeM3U(playlist: playlist, to: url.appendingPathComponent(filename), absolute: false, pathMapper: pathMapper)
        }
    }
    
    static func writeM3U(playlist: Playlist, to: URL, absolute: Bool, pathMapper: ((Track) -> URL?)? = nil) {
        let pathMapper: (Track) -> URL? = pathMapper ?? { $0.url }
        
        let tracks: [String] = playlist.tracksList.map { track in
            let info = "#EXTINF:\(track.durationSeconds ?? 0),\(track.rAuthor) - \(track.rTitle)"
            
            // TODO Put in path whether it exists or not
            let url = pathMapper(track)
            let path = absolute ? url?.path
                : url.map { $0.relativePath(from: to) ?? $0.path }
            
            if path == nil {
                print("Failed writing m3u for \(info) (path:\(String(describing: url?.path))) ")
            }
            
            return info + "\n" + (path ?? "unknown")
        }
        let contents = "#EXTM3U\n" + tracks.joined(separator: "\n")
        
        try! to.ensurePath()
        try! contents.write(to: to, atomically: true, encoding: .utf8)
    }
}
