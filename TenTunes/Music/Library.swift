
//
//  Library.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import CoreData

class Library {
    static var shared: Library!

    init(at: URL) {
        directory = at
        if !fetchMaster() {
            _masterPlaylist = PlaylistFolder(mox: viewMox)
            
            viewMox.insert(_masterPlaylist)
            save()
        }
    }
    
    var persistentContainer: NSPersistentContainer {
        return (NSApp.delegate as! AppDelegate).persistentContainer
    }
    
    var viewMox: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    @discardableResult
    func fetchMaster() -> Bool {
        let request: NSFetchRequest = PlaylistFolder.fetchRequest()
        request.predicate = NSPredicate(format: "parent = nil")
        do {
            _masterPlaylist = (try viewMox.fetch(request)).first
        }
        catch let error {
            print(error)
        }
        return _masterPlaylist != nil
    }
    
    var directory: URL
    
    var allTracks = PlaylistLibrary()
    var _masterPlaylist: PlaylistFolder!
    var masterPlaylist: PlaylistFolder {
        return _masterPlaylist
    }
    
    var _exportsRequireUpdate = false
    var exportSemaphore = DispatchSemaphore(value: 1)
    
    func performInBackground(task: @escaping (NSManagedObjectContext) -> Swift.Void) {
        persistentContainer.performBackgroundTask { mox in
            mox.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
            task(mox)
        }
    }

    // Querying
    
    func track(byId: NSManagedObjectID) -> Track? {
        return try! persistentContainer.viewContext.existingObject(with: byId) as? Track
    }

    func playlist(byId: NSManagedObjectID) -> Playlist? {
        return try! persistentContainer.viewContext.existingObject(with: byId) as? Playlist
    }
    
    var allPlaylists: [Playlist] {
        return try! persistentContainer.viewContext.fetch(NSFetchRequest<Playlist>(entityName: "Playlist"))
    }
    
    func isAffected(playlist: PlaylistProtocol, whenChanging: Playlist) -> Bool {
        if let playlist = playlist as? Playlist, path(of: whenChanging).contains(playlist) {
            return true
        }
        return playlist is PlaylistLibrary
    }

    func path(of: Playlist) -> [Playlist] {
        var path = [of]
        while let current = path.first, let parent = current.parent {
            path.insert(parent, at: 0)
        }
        return path
    }
    
    func position(of: Playlist) -> (PlaylistFolder, Int)? {
        if let parent = of.parent {
            return (parent, parent.childrenList.index(of: of)!)
        }
        return nil
    }
    
    func playlists(containing tracks: [Track]) -> [PlaylistManual] {
        let request: NSFetchRequest = PlaylistManual.fetchRequest()
        request.predicate = NSPredicate(format: "ANY tracks IN %@", tracks) // TODO
        return try! persistentContainer.viewContext.fetch(request)
    }

    // Editing
    
    func save(in mox: NSManagedObjectContext? = nil) {
        let mox = mox ?? viewMox
        
        if mox.hasChanges {
            do {
                
                try mox.save()
            }
            catch let error {
                print(error)
                exit(1)
            }
            
            _exportsRequireUpdate = true
        }
    }
    
    func modifiedTrackLibrary() {
        if ViewController.shared.trackController.history.playlist is PlaylistLibrary {
            ViewController.shared.trackController.desired._changed = true
        }
    }
    
    func editedTracks(of: Playlist) {
        // Should find a way for histories to check themselves? Or something
        // Might use lastChanged index and on every query check for sanity
        if isAffected(playlist: ViewController.shared.trackController.history.playlist, whenChanging: of) {
            ViewController.shared.trackController.desired._changed = true
        }
    }

    func isPlaylist(playlist: PlaylistProtocol) -> Bool {
        return playlist is Playlist
    }

    func isEditable(playlist: PlaylistProtocol) -> Bool {
        return playlist is PlaylistManual
    }
    
    func addTracks(_ tracks: [Track], to: PlaylistManual, above: Int? = nil) {
        // Add the tracks we're missing
        // TODO Allow duplicates after asking
        // Is set so by default not allowed
        to.addToTracks(NSOrderedSet(array: tracks))

        if let above = above {
            to.tracks = to.tracks.rearranged(elements: tracks, to: above)
        }
        
        editedTracks(of: to)
    }
    
    func addPlaylist(_ playlist: Playlist, to: PlaylistFolder? = nil, above: Int? = nil) {
        let to = to ?? masterPlaylist
        
        viewMox.insert(playlist)
        to.addToChildren(playlist)

        if let above = above {
            to.children = to.children.rearranged(elements: [playlist], to: above)
        }
        
        editedTracks(of: to)
        ViewController.shared.playlistController._outlineView.reloadData()
    }

    func remove(tracks: [Track], from: PlaylistManual, force: Bool = false) {
        guard force || isEditable(playlist: from) else {
            fatalError("Is not editable!")
        }
        
        from.removeFromTracks(NSOrderedSet(array: tracks))
        
        if let listening = ViewController.shared.history?.playlist, isAffected(playlist: listening, whenChanging: from) {
            ViewController.shared.history?.filter { !tracks.contains($0) }
        }
        
        editedTracks(of: from)
    }
    
    func delete(tracks: [Track]) {
        // First remove them from all current playlists like we did intentionally
        // This ensures all views etc update properly
        for relevant in playlists(containing: tracks) {
            remove(tracks: tracks, from: relevant)
        }
        
        for track in tracks {
            viewMox.delete(track)
        }
    }
    
    func delete(playlists: [Playlist]) {
        guard (playlists.allMatch { isPlaylist(playlist: $0) }) else {
            fatalError("Not a playlist!")
        }
        
        for playlist in playlists {
            viewMox.delete(playlist)
            editedTracks(of: playlist) // Possibly update parents
            
            if let current = ViewController.shared.trackController.history.playlist as? Playlist, current == playlist {
                // Deleted our current playlist! :<
                ViewController.shared.trackController.set(playlist: allTracks)
            }
        }
        
        ViewController.shared.playlistController._outlineView.reloadData()
    }
    
    // iTunes
    
    func findTrack(byITunesID: String) -> Track? {
        let request = NSFetchRequest<Track>(entityName: "Track")
        request.predicate = NSPredicate(format: "iTunesID == %@", byITunesID)
        return try! persistentContainer.viewContext.fetch(request).first
    }
}

// Pasteboard

extension Library {
    func writePlaylistID(of: Playlist) -> Any? {
        return of.objectID.uriRepresentation().absoluteString
    }
    
    func restoreFrom(playlistID: Any) -> Playlist? {
        if let string = playlistID as? String, let uri = URL(string: string), let id = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: uri) {
            return playlist(byId: id)
        }
        return nil
    }
    
    func writeTrack(_ track: Track, toPasteboarditem item: NSPasteboardItem) {
        item.setString(track.objectID.uriRepresentation().absoluteString, forType: Track.pasteboardType)
        
        if let url = track.url {
            item.setString(url.absoluteString, forType: .fileURL)
        }
    }
    
    func readTrack(fromPasteboardItem item: NSPasteboardItem) -> Track? {
        if let idString = item.string(forType: Track.pasteboardType), let url = URL(string: idString), let id = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
            return track(byId: id)
        }
        return nil
    }

    func writePlaylist(_ playlist: Playlist, toPasteboarditem item: NSPasteboardItem) {
        item.setString(playlist.objectID.uriRepresentation().absoluteString, forType: Playlist.pasteboardType)
    }
    
    func readPlaylist(fromPasteboardItem item: NSPasteboardItem) -> Playlist? {
        if let idString = item.string(forType: Playlist.pasteboardType), let url = URL(string: idString), let id = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
            return playlist(byId: id)
        }
        return nil
    }
}
