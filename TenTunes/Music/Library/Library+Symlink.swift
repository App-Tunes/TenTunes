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
                Library.writeSymlinks(playlist: playlist, to: url.appendingPathComponent(name), pather: mediaLocation.pather(absolute: true))
            }
        }
    }
    
    static func writeRemoteSymlinks(_ playlists: [Playlist], to: URL, pather: @escaping (Track, URL) -> String?) {
        Library.iterate(playlists: playlists, changed: nil, in: to) { (url, playlist) in
            if let playlist = playlist as? PlaylistManual {
                let name = playlist.name.asFileName
                Library.writeSymlinks(playlist: playlist, to: url.appendingPathComponent(name), pather: pather)
            }
        }
    }
    
    static func writeSymlinks(playlist: PlaylistManual, to playlistURL: URL, pather: (Track, URL) -> String?) {
        // TODO Clean Up before
        for track in playlist.tracksList {
            if let trackURL = pather(track, playlistURL) {
                let fileURL = playlistURL.appendingPathComponent((trackURL as NSString).lastPathComponent)
                try! playlistURL.ensureDirectory()
                try? FileManager.default.createSymbolicLink(atPath: fileURL.path, withDestinationPath: trackURL)
            }
        }
    }
}
