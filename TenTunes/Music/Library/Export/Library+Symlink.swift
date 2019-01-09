//
//  Library+Symlink.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.06.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library.Export {
    func symlinks(tracks: [Track], playlists: [Playlist]) {
        Library.Export.iterate(playlists: playlists, changed: nil, in: url(title: "Alias")) { (url, playlist) in
            if !(playlist is PlaylistFolder) {
                let name = playlist.name.asFileName
                Library.Export.symlinks(playlist: playlist, to: url.appendingPathComponent(name), pather: library.mediaLocation.pather(absolute: true))
            }
        }
    }
    
    static func remoteSymlinks(_ playlists: [Playlist], to: URL, pather: @escaping (Track, URL) -> String?) {
        Library.Export.iterate(playlists: playlists, changed: nil, in: to) { (url, playlist) in
            if !(playlist is PlaylistFolder) {
                let name = playlist.name.asFileName
                Library.Export.symlinks(playlist: playlist, to: url.appendingPathComponent(name), pather: pather)
            }
        }
    }
    
    static func symlinks(playlist: Playlist, to playlistURL: URL, pather: (Track, URL) -> String?) {
        // TODO Clean Up before
        for track in playlist.tracksList {
            if let trackURL = pather(track, playlistURL) {
                let fileURL = playlistURL.appendingPathComponent((trackURL as NSString).lastPathComponent)
                try! playlistURL.ensureIsDirectory()
                try? FileManager.default.createSymbolicLink(atPath: fileURL.path, withDestinationPath: trackURL)
            }
        }
    }
}
