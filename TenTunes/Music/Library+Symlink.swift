//
//  Library+Symlink.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.06.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library {
    func writeSymlinks(tracks: [Track], playlists: [Playlist]) {
        Library.iterate(playlists: playlists, changed: nil, in: exportURL(title: "Alias")) { (url, playlist) in
            if let playlist = playlist as? PlaylistManual {
                let name = playlist.name.asFileName
                Library.writeSymlinks(playlist: playlist, to: url.appendingPathComponent(name), pather: mediaLocation.pather())
            }
        }

        Library.iterate(playlists: playlists, changed: nil, in: exportURL(title: "Alias (Static)")) { (url, playlist) in
            if let playlist = playlist as? PlaylistManual {
                let name = playlist.name.asFileName
                Library.writeSymlinks(playlist: playlist, to: url.appendingPathComponent(name), pather: mediaLocation.pather(absolute: true))
            }
        }
    }
    
    static func writeSymlinks(playlist: PlaylistManual, to: URL, pather: (Track, URL) -> String?) {
        // TODO Clean Up before
        for track in playlist.tracksList {
            if let dest = pather(track, to) {
                let path = to.appendingPathComponent((dest as NSString).lastPathComponent).path
                try! to.ensureDirectory()
                try? FileManager.default.createSymbolicLink(atPath: path, withDestinationPath: dest)
            }
        }
    }
}
