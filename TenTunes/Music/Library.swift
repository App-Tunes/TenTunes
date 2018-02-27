
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
    
    func position(of: Playlist) -> (Playlist, Int)? {
        if let parent = parent(of: of) {
            return (parent, parent.children!.index(of: of)!)
        }
        return nil
    }

    // Editing

    func isPlaylist(playlist: Playlist) -> Bool {
        return playlist != allTracks
    }

    func isEditable(playlist: Playlist) -> Bool {
        return !playlist.isFolder && playlist != allTracks
    }
    
    func add(from: Library) {
        for (_, track) in from.database {
            add(track: track)
        }
        
        from.masterPlaylist.name = "iTunes Library"
        masterPlaylist.add(child: from.masterPlaylist)
        
        // TODO Make up new IDs
        playlistParents.merge(from.playlistParents, uniquingKeysWith: { _,_ in fatalError("Duplicate playlist parents??") })
        playlistDatabase.merge(from.playlistDatabase, uniquingKeysWith: { _,_ in fatalError("Duplicate playlist IDs") })

        ViewController.shared.playlistController._outlineView.reloadData()
        ViewController.shared.trackController.desired._changed = true
    }

    func add(track: Track) {
        if database.keys.contains(track.id) {
            fatalError("Duplicate track ID")
        }
        
        database[track.id] = track
        allTracks.tracks.append(track)
    }
    
    func add(playlist: Playlist, to: Playlist? = nil, at: Int? = nil) {
        let to = to ?? masterPlaylist
        guard to.isFolder else {
            fatalError("Parent not a folder")
        }
        let at = at ?? to.children!.count

        playlistDatabase[playlist.id] = playlist
        to.children?.insert(playlist, at: at)
        playlistParents[playlist.id] = to
        
        if playlist.size > 0, let path = path(of: to) {
            recalculate(playlists: path)
        }
        
        ViewController.shared.playlistController._outlineView.reloadData()
    }

    func remove(tracks: [Track], from: Playlist, force: Bool = false) {
        guard force || isEditable(playlist: from) else {
            fatalError("Is not editable!")
        }
        
        from.tracks.remove(all: tracks)
        
        let path = self.path(of: from)!
        for parent in path.dropLast().reversed() {
            // Only remove tracks if other children don't have it
            parent.tracks = parent.tracks.filter { !tracks.contains($0) || (parent.children!.flatMap { $0.tracks }).contains($0) }
        }
        
        // Should find a way for histories to check themselves? Or something
        // Might use lastChanged index and on every query check for sanity
        if (ViewController.shared.history?.playlist ?=> path.contains) ?? false {
            ViewController.shared.history?.filter { !tracks.contains($0) }
        }
        
        // We can calcuate the view async
        if path.contains(ViewController.shared.trackController.history.playlist) {
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
        guard (playlists.allMatch { isPlaylist(playlist: $0) }) else {
            fatalError("Not a playlist!")
        }
        
        for playlist in playlists {
            // Clear it so the parents are updated
            remove(tracks: playlist.tracks, from: playlist)
            
            // Remove from parents
            parent(of: playlist)?.children!.remove(element: playlist)
        }
        
        ViewController.shared.playlistController._outlineView.reloadData()
    }
    
    // Must be in descending order
    func recalculate(playlists: [Playlist]) {
        guard (playlists.allMatch { $0.isFolder }) else {
            fatalError("Not a folder!")
        }
        
        for playlist in playlists.reversed() {
            playlist.tracks = Array(Set<Track>(playlist.children!.flatMap { $0.tracks }))
        }
    }
}
