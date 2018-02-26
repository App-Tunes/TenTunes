
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
    var playlistParents: [String: Playlist] = [:]

    func add(track: Track) {
        database[track.id] = track
        allTracks.tracks.append(track)
    }

    func add(playlist: Playlist, to: Playlist? = nil) {
        playlistDatabase[playlist.id] = playlist
        
        let to = to ?? masterPlaylist
        to.children?.append(playlist)
        playlistParents[playlist.id] = to
        
        to.tracks += playlist.tracks
    }
    
    func track(byId: Int) -> Track? {
        return database[byId]
    }

    func playlist(byId: String) -> Playlist? {
        return playlistDatabase[byId]
    }
    
    func parent(of: Playlist) -> Playlist? {
        return playlistParents[of.id]
    }
    
    func path(of: Playlist) -> [Playlist]? {
        var path = [of]
        while let prev = parent(of: path.first!) {
            path.insert(prev, at: 0)
        }
        return path
    }
    
    func remove(track: Track, from: Playlist) {
        guard !from.isFolder && from != allTracks else {
            fatalError("Is folder!")
        }
        
        for parent in path(of: from)! {
            parent.tracks.remove(element: track)
        }
        
        allTracks.tracks.remove(element: track)

        // Should find a way for histories to check themselves? Or something
        // Might use lastChanged index and on every query check for sanity
        ViewController.shared.history?.filter { $0 != track }
        
        // We can calcuate the view async
        ViewController.shared.trackController.desired._changed = true
    }
}
