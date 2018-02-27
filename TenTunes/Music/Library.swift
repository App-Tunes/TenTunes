
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
            addTrackToLibrary(track)
        }
        
        from.masterPlaylist.name = "iTunes Library"
        masterPlaylist.add(child: from.masterPlaylist)
        
        // TODO Make up new IDs
        playlistParents.merge(from.playlistParents, uniquingKeysWith: { _,_ in fatalError("Duplicate playlist parents??") })
        playlistDatabase.merge(from.playlistDatabase, uniquingKeysWith: { _,_ in fatalError("Duplicate playlist IDs") })

        ViewController.shared.playlistController._outlineView.reloadData()
        ViewController.shared.trackController.desired._changed = true
    }

    func addTrackToLibrary(_ track: Track) {
        if database.keys.contains(track.id) {
            fatalError("Duplicate track ID")
        }
        
        database[track.id] = track
        allTracks.tracks.append(track)
    }
    
    func addTracks(_ tracks: [Track], to: Playlist, above: Int? = nil) {
        // TODO Allow duplicates after asking
        let above = above ?? to.size
        
        // Add the tracks we're missing
        to.tracks.append(contentsOf: tracks.filter { !to.tracks.contains($0) })
        // Rearrange the tracks
        to.tracks.rearrange(elements: tracks, to: above)
        
        // TODO Adjust parents' order? I mean, it sucks anyway
        // TODO Add to playing playlists? Meh
        let path = self.path(of: to)!

        if path.contains(ViewController.shared.trackController.history.playlist) {
            ViewController.shared.trackController.desired._changed = true
        }
    }
    
    func addPlaylist(_ playlist: Playlist, to: Playlist? = nil, above: Int? = nil) {
        let to = to ?? masterPlaylist
        guard to.isFolder else {
            fatalError("Parent not a folder")
        }
        let above = above ?? to.children!.count

        var copy: Playlist? = nil
        
        // If we're still in another playlist
        if let (parent, idx) = position(of: playlist) {
            // Add a hollow copy of this playlist
            copy = Playlist(folder: false)
            copy!.tracks.append(contentsOf: playlist.tracks)
            
            // Replace our playlist with the hollow copy
            parent.children![idx] = copy!
            playlistParents[copy!.id] = parent
        }
        
        playlistDatabase[playlist.id] = playlist
        to.children?.insert(playlist, at: above)
        playlistParents[playlist.id] = to
        
        // Delete the copy so all tracks update
        // Do this after adding the new one so we don't have to recalculate indices
        if let copy = copy {
            delete(playlists: [copy])
        }
        
        // TODO Do a change add
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
        
        // Remove from database
        remove(tracks: tracks, from: allTracks, force: true)
        database.removeValues(forKeys: tracks.map { $0.id })
    }
    
    func delete(playlists: [Playlist]) {
        guard (playlists.allMatch { isPlaylist(playlist: $0) }) else {
            fatalError("Not a playlist!")
        }
        
        for playlist in playlists {
            // Delete the children first
            if playlist.isFolder {
                delete(playlists: playlist.children!)
                
                // Convert to a regular ol playlist
                playlist.children = nil
            }

            // Clear it so the parents are updated
            remove(tracks: playlist.tracks, from: playlist)
            
            // Remove from parents
            let (parent, idx) = position(of: playlist)!
            parent.children!.remove(at: idx)
        }
        
        // Remove from database
        let keys = playlists.map { $0.id }
        playlistDatabase.removeValues(forKeys: keys)
        playlistParents.removeValues(forKeys: keys)
        
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

// Pasteboard

extension Library {
    func writeTrack(_ track: Track, toPasteboarditem item: NSPasteboardItem) {
        item.setString(String(track.id), forType: Track.pasteboardType)
    }
    
    func readTrack(fromPasteboardItem item: NSPasteboardItem) -> Track? {
        if let id = item.string(forType: Track.pasteboardType) ?=> Int.init {
            return track(byId: id)
        }
        return nil
    }

    func writePlaylist(_ playlist: Playlist, toPasteboarditem item: NSPasteboardItem) {
        item.setString(String(playlist.id), forType: Playlist.pasteboardType)
    }
    
    func readPlaylist(fromPasteboardItem item: NSPasteboardItem) -> Playlist? {
        if let id = item.string(forType: Playlist.pasteboardType) {
            return playlist(byId: id)
        }
        return nil
    }
}
