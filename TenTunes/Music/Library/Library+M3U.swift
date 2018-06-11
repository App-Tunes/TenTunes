//
//  Library+M3U.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library.Export {
    func m3uPlaylists(playlists: [Playlist], changed: Set<NSManagedObjectID>?) {
        Library.Export.iterate(playlists: playlists, changed: changed, in: url(title: "M3U")) { (url, playlist) in
            let filename = playlist.name.asFileName + ".m3u"
            Library.Export.m3u(playlist: playlist, to: url.appendingPathComponent(filename), pather: library.mediaLocation.pather(absolute: true))
        }
    }
    
    static func remoteM3uPlaylists(_ playlists: [Playlist], to: URL, pather: @escaping (Track, URL) -> String?) {
        Library.Export.iterate(playlists: playlists, changed: nil, in: to) { (url, playlist) in
            let filename = playlist.name.asFileName + ".m3u"
            Library.Export.m3u(playlist: playlist, to: url.appendingPathComponent(filename), pather: pather)
        }
    }
    
    static func m3u(playlist: Playlist, to: URL, pather: (Track, URL) -> String?) {
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
