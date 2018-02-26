
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
    
    // Querying
    
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
    
    // Editing

    func isPlaylist(playlist: Playlist) -> Bool {
        return playlist != allTracks
    }

    func isEditable(playlist: Playlist) -> Bool {
        return !playlist.isFolder && playlist != allTracks
    }
    
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

    func remove(tracks: [Track], from: Playlist) {
        guard isEditable(playlist: from) else {
            fatalError("Is not editable!")
        }
        
        for parent in path(of: from)! {
            parent.tracks.remove(all: tracks)
        }
        
        allTracks.tracks.remove(all: tracks)

        // Should find a way for histories to check themselves? Or something
        // Might use lastChanged index and on every query check for sanity
        ViewController.shared.history?.filter { !tracks.contains($0) }
        
        // We can calcuate the view async
        ViewController.shared.trackController.desired._changed = true
    }
    
    func delete(playlists: [Playlist]) {
        guard !(playlists.map { isPlaylist(playlist: $0) }).contains(false) else {
            fatalError("Not a playlist!")
        }
        
        for playlist in playlists {
            parent(of: playlist)?.children!.remove(element: playlist)
        }
        
        ViewController.shared.playlistController._outlineView.reloadData()
    }
}
