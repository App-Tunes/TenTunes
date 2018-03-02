
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
    
    var database: [UUID: Track] = [:]
    var allTracks: Playlist = Playlist(folder: false)

    var playlistDatabase: [UUID: Playlist] = [:]
    var masterPlaylist: Playlist = Playlist(folder: true)
    var playlistParents: [UUID: Playlist] = [:]
    
    var url: URL
    
    init() {
        masterPlaylist.name = "Master"
        allTracks.name = "Library"
        
        url = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first!.appendingPathComponent("Ten Tunes")
        
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
    }
    
    // Querying
    
    func track(byId: UUID) -> Track? {
        return database[byId]
    }

    func playlist(byId: UUID) -> Playlist? {
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
    
    func playlists(containing tracks: [Track]) -> [Playlist] {
        return allPlaylists.filter { $0.tracks.contains { tracks.contains($0) } }
    }

    // Editing

    func isPlaylist(playlist: Playlist) -> Bool {
        return playlist != allTracks
    }

    func isEditable(playlist: Playlist) -> Bool {
        return !playlist.isFolder && playlist != allTracks
    }
    
    func add(from: Library) {
        // Add stuff to library
        for (_, track) in from.database { addTrackToLibrary(track) }
        playlistParents.merge(from.playlistParents, uniquingKeysWith: { _,_ in fatalError("Duplicate playlist parents??") })
        playlistDatabase.merge(from.playlistDatabase, uniquingKeysWith: { _,_ in fatalError("Duplicate playlist IDs") })
        addPlaylist(from.masterPlaylist, to: masterPlaylist, above: nil)
    }

    func addTrackToLibrary(_ track: Track) {
        guard database.insertNewValue(value: track, forKey: track.id) else { return }
        
        database[track.id] = track
        allTracks.tracks.append(track)
    }
    
    func addTracks(_ tracks: [Track], to: Playlist, above: Int? = nil) {
        // Add the tracks we're missing
        // TODO Allow duplicates after asking
        to.tracks.append(contentsOf: tracks.filter { !to.tracks.contains($0) })

        if let above = above {
            // Rearrange the tracks if we specified a position
            to.tracks.rearrange(elements: tracks, to: above)
        }
        
        // TODO Adjust parents' order? I mean, it sucks anyway
        // TODO Add to playing playlists? Meh
        let path = self.path(of: to)!

        let current = ViewController.shared.trackController.history.playlist
        if path.contains(current) || current == allTracks {
            ViewController.shared.trackController.desired._changed = true
        }
    }
    
    func addPlaylist(_ playlist: Playlist, to: Playlist? = nil, above: Int? = nil) {
        let to = to ?? masterPlaylist
        guard to.isFolder else {
            fatalError("Parent not a folder")
        }
        
        playlistDatabase.insertNewValue(value: playlist, forKey: playlist.id)
        
        let above = above ?? to.children!.count

        var copy: Playlist? = nil
        let position = self.position(of: playlist)
        
        // If we're still in another playlist
        if let position = position {
            let parent = position.0
            let idx = position.1
            
            // Replace our playlist with a dummy so indices stay the same
            copy = Playlist(folder: false)
            parent.children![idx] = copy!
            playlistParents[copy!.id] = parent
        }
        
        // Add all tracks to possibly adjust views
        addTracks(playlist.tracks, to: to)
        
        to.children?.insert(playlist, at: above)
        playlistParents[playlist.id] = to
        
        if let copy = copy {
            if let position = position, position.0 === to {
                // If we move within the same parent, just remove our copy
                position.0.children!.remove(element: copy)
            }
            else {
                // Delete the copy so all tracks update
                // Do this after adding the new one so we don't have to recalculate indices
                delete(playlists: [copy])
            }
        }
        
        ViewController.shared.playlistController._outlineView.reloadData()
    }

    func remove(tracks: [Track], from: Playlist, force: Bool = false) {
        guard force || isEditable(playlist: from) else {
            fatalError("Is not editable!")
        }
        
        from.tracks.remove(all: tracks)
        
        // Should find a way for histories to check themselves? Or something
        // Might use lastChanged index and on every query check for sanity
        let path = self.path(of: from)!

        let listening = ViewController.shared.history?.playlist
        if let listening = listening, path.contains(listening) || listening == allTracks {
            ViewController.shared.history?.filter { !tracks.contains($0) }
        }
        
        let current = ViewController.shared.trackController.history.playlist
        if path.contains(current) || current == allTracks {
            // We can calcuate the view async
            ViewController.shared.trackController.desired._changed = true
        }
    }
    
    func delete(tracks: [Track]) {
        let relevant = playlists(containing: tracks)
        
        for playlist in relevant {
            remove(tracks: tracks, from: playlist, force: true)
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
            if !playlistDatabase.keys.contains(playlist.id) {
                // Already deleted
                // Happens when folders are deleted at the same with their children
                continue
            }

            
            // Delete the children first
            if playlist.isFolder {
                delete(playlists: playlist.children!)
            }
            
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
    
    // iTunes
    
    func findTrack(byITunesID: String) -> Track? {
        return database.values.first { $0.iTunesPersistentID == byITunesID }
    }
}

// Pasteboard

extension Library {
    func writeTrack(_ track: Track, toPasteboarditem item: NSPasteboardItem) {
        item.setString(track.id.uuidString, forType: Track.pasteboardType)
        
        if let url = track.url {
            item.setString(url.absoluteString, forType: .fileURL)
        }
    }
    
    func readTrack(fromPasteboardItem item: NSPasteboardItem) -> Track? {
        if let idString = item.string(forType: Track.pasteboardType), let id = UUID(uuidString: idString) {
            return track(byId: id)
        }
        return nil
    }

    func writePlaylist(_ playlist: Playlist, toPasteboarditem item: NSPasteboardItem) {
        item.setString(playlist.id.uuidString, forType: Playlist.pasteboardType)
    }
    
    func readPlaylist(fromPasteboardItem item: NSPasteboardItem) -> Playlist? {
        if let idString = item.string(forType: Playlist.pasteboardType), let id = UUID(uuidString: idString) {
            return playlist(byId: id)
        }
        return nil
    }
}
