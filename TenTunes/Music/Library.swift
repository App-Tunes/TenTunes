
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
    
    var allPlaylists: [Playlist] {
        return Array.flattened(root: masterPlaylist) { $0.children }
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

    func remove(tracks: [Track], from: Playlist, force: Bool = false) {
        guard force || isEditable(playlist: from) else {
            fatalError("Is not editable!")
        }
        
        from.tracks.remove(all: tracks)

        for parent in path(of: from)!.dropLast().reversed() {
            // Only remove tracks if other children don't have it
            parent.tracks = parent.tracks.filter { !tracks.contains($0) || (parent.children!.flatMap { $0.tracks }).contains($0) }
        }
        
        // Should find a way for histories to check themselves? Or something
        // Might use lastChanged index and on every query check for sanity
        if ViewController.shared.history?.playlist == from {
            ViewController.shared.history?.filter { !tracks.contains($0) }
        }
        
        // We can calcuate the view async
        if ViewController.shared.trackController.history.playlist == from {
            ViewController.shared.trackController.desired._changed = true
        }
    }
    
    func delete(tracks: [Track]) {
        let relevant = allPlaylists.filter { $0.tracks.contains { tracks.contains($0) } }
        
        for playlist in relevant where isEditable(playlist: playlist) {
            remove(tracks: tracks, from: playlist)
        }
        
        remove(tracks: tracks, from: allTracks, force: true)
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
