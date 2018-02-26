
//
//  Library.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Library {
    static var shared: Library = Library()
    
    var database: [Int: Track] = [:]
    var allTracks: Playlist = Playlist(folder: false)

    var playlistDatabase: [String: Playlist] = [:]
    var masterPlaylist: Playlist = Playlist(folder: true)
    
    func add(track: Track) {
        database[track.id] = track
        allTracks.tracks.append(track)
    }

    func add(playlist: Playlist, to: Playlist? = nil) {
        playlistDatabase[playlist.id] = playlist
        
        let to = to ?? masterPlaylist
        to.children?.append(playlist)
        
        to.tracks += playlist.tracks
    }
    
    func track(byId: Int) -> Track? {
        return database[byId]
    }

    func playlist(byId: String) -> Playlist? {
        return playlistDatabase[byId]
    }
}
