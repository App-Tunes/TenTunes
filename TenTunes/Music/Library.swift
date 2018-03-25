
//
//  Library.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import CoreData

class Library : NSPersistentContainer {
    static var shared: Library {
        return (NSApp.delegate as! AppDelegate).persistentContainer
    }

    init(name: String, at: URL) {
        directory = at
        mediaLocation = MediaLocation(directory: directory.appendingPathComponent("Media"))

        super.init(name: name, managedObjectModel: NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: name, withExtension: "momd")!)!)
        
        let libraryURL = at.appendingPathComponent("Library")
        try! FileManager.default.createDirectory(at: libraryURL, withIntermediateDirectories: true, attributes: nil)
        
        let description = NSPersistentStoreDescription(url: libraryURL.appendingPathComponent("library.sqlite"))
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        
        persistentStoreDescriptions = [description]
        
        loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        
        registerObservers()

        if !fetchMaster() {
            _masterPlaylist = PlaylistFolder(mox: viewContext)
            _masterPlaylist.name = "Master Playlist"
            
            viewContext.insert(_masterPlaylist)
            save()
        }
    }
    
    @discardableResult
    func fetchMaster() -> Bool {
        let request: NSFetchRequest = PlaylistFolder.fetchRequest()
        request.predicate = NSPredicate(format: "parent = nil")
        do {
            let applicable = try viewContext.fetch(request)
            if applicable.count > 1 {
                fatalError("Multiple applicable master playlists!")
            }
            
            _masterPlaylist = applicable.first
        }
        catch let error {
            print(error)
        }
        return _masterPlaylist != nil
    }
    
    var directory: URL
    var mediaLocation: MediaLocation
    
    var allTracks = PlaylistLibrary()
    var _masterPlaylist: PlaylistFolder!
    var masterPlaylist: PlaylistFolder {
        return _masterPlaylist
    }
    
    var _exportChanged: Set<NSManagedObjectID> = Set()
    var exportSemaphore = DispatchSemaphore(value: 1)
    
    func performInBackground(task: @escaping (NSManagedObjectContext) -> Swift.Void) {
        performBackgroundTask { mox in
            mox.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
            task(mox)
        }
    }

    // Querying
    
    func track(byId: NSManagedObjectID) -> Track? {
        return (try? viewContext.existingObject(with: byId)) as? Track
    }

    func playlist(byId: NSManagedObjectID) -> Playlist? {
        return (try? viewContext.existingObject(with: byId)) as? Playlist
    }
    
    var allPlaylists: [Playlist] {
        return try! viewContext.fetch(NSFetchRequest<Playlist>(entityName: "Playlist"))
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
        return try! viewContext.fetch(request)
    }

    // Editing
    
    func save(in mox: NSManagedObjectContext? = nil) {
        let mox = mox ?? viewContext
        
        if mox.hasChanges {
            do {
                
                try mox.save()
            }
            catch let error {
                print(error)
                exit(1)
            }
            
            _exportChanged = _exportChanged.union(mox.registeredObjects.map { $0.objectID })
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
    }
    
    func addPlaylist(_ playlist: Playlist, to: PlaylistFolder? = nil, above: Int? = nil) {
        let to = to ?? masterPlaylist
        
        to.addToChildren(playlist)

        if let above = above {
            to.children = to.children.rearranged(elements: [playlist], to: above)
        }        
    }

    func remove(tracks: [Track], from: PlaylistManual, force: Bool = false) {
        guard force || isEditable(playlist: from) else {
            fatalError("Is not editable!")
        }
        
        from.removeFromTracks(NSOrderedSet(array: tracks))
        
        if let listening = ViewController.shared.history?.playlist, isAffected(playlist: listening, whenChanging: from) {
            ViewController.shared.history?.filter { !tracks.contains($0) }
        }
    }
    
    func delete(playlists: [Playlist]) {
        guard (playlists.allMatch { isPlaylist(playlist: $0) }) else {
            fatalError("Not a playlist!")
        }
        
        viewContext.delete(all: playlists)
    }
    
    // iTunes
    
    func findTrack(byITunesID: String) -> Track? {
        let request = NSFetchRequest<Track>(entityName: "Track")
        request.predicate = NSPredicate(format: "iTunesID == %@", byITunesID)
        return try! viewContext.fetch(request).first
    }
}

// Pasteboard

extension Library {
    func writePlaylistID(of: Playlist) -> Any? {
        return of.objectID.uriRepresentation().absoluteString
    }
    
    func restoreFrom(playlistID: Any) -> Playlist? {
        if let string = playlistID as? String, let uri = URL(string: string), let id = persistentStoreCoordinator.managedObjectID(forURIRepresentation: uri) {
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
        if let idString = item.string(forType: Track.pasteboardType), let url = URL(string: idString), let id = persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
            return track(byId: id)
        }
        return nil
    }

    func writePlaylist(_ playlist: Playlist, toPasteboarditem item: NSPasteboardItem) {
        item.setString(playlist.objectID.uriRepresentation().absoluteString, forType: Playlist.pasteboardType)
    }
    
    func readPlaylist(fromPasteboardItem item: NSPasteboardItem) -> Playlist? {
        if let idString = item.string(forType: Playlist.pasteboardType), let url = URL(string: idString), let id = persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
            return playlist(byId: id)
        }
        return nil
    }
}

extension Library {
    func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: viewContext)
    }
    
    @IBAction func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()

        for delete in deletes {
            if let track = delete as? Track {
                mediaLocation.delete(track: track)
            }
        }
    }
}
