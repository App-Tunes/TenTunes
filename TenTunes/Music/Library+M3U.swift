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
        Library.iterate(playlists: playlists, changed: changed, in: exportURL(title: "M3U")) { (url, playlist) in
            let filename = playlist.name.asFileName + ".m3u"
            Library.writeM3U(playlist: playlist, to: url.appendingPathComponent(filename), pather: mediaLocation.pather())
        }

        Library.iterate(playlists: playlists, changed: changed, in: exportURL(title: "M3U (Static)")) { (url, playlist) in
            let filename = playlist.name.asFileName + ".m3u"
            Library.writeM3U(playlist: playlist, to: url.appendingPathComponent(filename), pather: mediaLocation.pather(absolute: true))
        }
    }
    
    static func writeRemoteM3UPlaylists(_ playlists: [Playlist], to: URL, pather: @escaping (Track, URL) -> String?) {
        Library.iterate(playlists: playlists, changed: nil, in: to) { (url, playlist) in
            let filename = playlist.name.asFileName + ".m3u"
            Library.writeM3U(playlist: playlist, to: url.appendingPathComponent(filename), pather: pather)
        }
    }
    
    static func writeM3U(playlist: Playlist, to: URL, pather: (Track, URL) -> String?) {
        let tracks: [String] = playlist.tracksList.map { track in
            let info = "#EXTINF:\(track.durationSeconds ?? 0),\(track.rAuthor) - \(track.rTitle)"
            
            // TODO Put in path whether it exists or not
            if let path = pather(track, to.deletingLastPathComponent()) {
                return info + "\n" + path
            }

            print("Failed writing m3u for \(info)")
            return info + "\nunknown"
        }
        let contents = "#EXTM3U\n" + tracks.joined(separator: "\n")
        
        try! to.ensurePath()
        
        var data = contents.data(using: .windowsCP1252, allowLossyConversion: false)
        if data == nil {
            print("Lossy Conversion of m3u \(to)!")
            data = contents.data(using: .windowsCP1252, allowLossyConversion: true)
        }
        
        try! data!.write(to: to)
    }
}
