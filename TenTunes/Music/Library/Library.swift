
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
    static let libraryFolderName = "Library.ttl"
    
    static var shared: Library {
        return (NSApp.delegate as! AppDelegate).persistentContainer
    }

    init?(name: String, at: URL, create: Bool?) {
        let libraryURL = at.appendingPathComponent(Library.libraryFolderName)
        let storeURL = libraryURL.appendingPathComponent("library.sqlite")
        
        if let create = create, create == FileManager.default.fileExists(atPath: storeURL.path) {
            return nil
        }

        directory = at
        mediaLocation = MediaLocation(directory: directory.appendingPathComponent("Media"))

        super.init(name: name, managedObjectModel: NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: name, withExtension: "momd")!)!)
        
        if (try? libraryURL.ensureIsDirectory()) == nil {
            return nil
        }
        
        let description = NSPersistentStoreDescription(url: storeURL)
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

        allTracks = PlaylistLibrary(context: viewContext)
        
        _masterPlaylist = fetchCreateSpecialFolder(key: "Master Playlist") { playlist in
            playlist.name = "Master Playlist"
        }
        
        _tagPlaylist = fetchCreateSpecialFolder(key: "Tag Playlist") { playlist in
            playlist.name = "Tags"
            _masterPlaylist.addPlaylist(playlist)
        }
    }
    
    func fetchCreateSpecialFolder(key: String, create: (PlaylistFolder) -> Swift.Void) -> PlaylistFolder {
        if let url = defaultMetadata[key], let playlist = restoreFrom(playlistID: url) as? PlaylistFolder {
            return playlist
        }
        else {
            let playlist = PlaylistFolder(context: viewContext)
            
            create(playlist)
            
            viewContext.insert(playlist)
            try! viewContext.save()
            
            // Need to do this after initial save, otherwise the ID is temporary.............
            defaultMetadata[key] = writePlaylistID(of: playlist)
            try! viewContext.save()
            
            return playlist
        }
    }
    
    var directory: URL
    var mediaLocation: MediaLocation
    
    var allTracks: PlaylistLibrary!
    var _masterPlaylist: PlaylistFolder!
    var masterPlaylist: PlaylistFolder {
        return _masterPlaylist
    }
    
    var _tagPlaylist: PlaylistFolder!
    var tagPlaylist: PlaylistFolder {
        return _tagPlaylist
    }

    var sanityChanged = true
    var sanitySemaphore = DispatchSemaphore(value: 1)

    var _exportChanged: Set<NSManagedObjectID>? = Set()
    var exportSemaphore = DispatchSemaphore(value: 1)
    
    var _allAuthors: Set<Artist>?
    var allAuthors: Set<Artist> {
        if _allAuthors == nil {
            _allAuthors = Set(allTracks.tracksList.flatMap { $0.authors })
        }
        return _allAuthors!
    }
    
    var _allGenres: Set<String>?
    var allGenres: Set<String> {
        if _allGenres == nil {
            _allGenres = Set(allTracks.tracksList.compactMap { $0.genre })
        }
        return _allGenres!
    }
    
    var _allAlbums: Set<Album>?
    var allAlbums: Set<Album> {
        if _allAlbums == nil {
            _allAlbums = Set(allTracks.tracksList.compactMap { $0.rAlbum })
        }
        return _allAlbums!
    }
    
    // Querying
    
    func track(byId: NSManagedObjectID, in context: NSManagedObjectContext? = nil) -> Track? {
        let context = context ?? viewContext
        return (try? context.existingObject(with: byId)) as? Track
    }

    func playlist(byId: NSManagedObjectID, in context: NSManagedObjectContext? = nil) -> Playlist? {
        let context = context ?? viewContext
        return (try? context.existingObject(with: byId)) as? Playlist
    }
    
    func allPlaylists(in context: NSManagedObjectContext? = nil) -> [Playlist] {
        let context = context ?? viewContext
        return try! context.fetch(NSFetchRequest<Playlist>(entityName: "Playlist"))
    }
    
    func allTags(in context: NSManagedObjectContext? = nil) -> [Playlist] {
        // TODO Instead only use all children method of tagPlaylist
        return allPlaylists(in: context).filter { self.isTag(playlist: $0) }
    }
    
    func isAffected(playlist: PlaylistProtocol, whenChanging: Playlist) -> Bool {
        if let playlist = playlist as? Playlist, whenChanging == playlist {
            return true
        }
        
        if let playlist = playlist as? PlaylistFolder, path(of: whenChanging).contains(playlist) {
            return true
        }
        
        if playlist is PlaylistSmart || playlist is PlaylistCartesian {
            return true // TODO Only return true if actually affected (tags contain it or something)
        }
        
        return false
    }
    
    func isAffected(playlist: PlaylistProtocol, whenModifying: Track) -> Bool {
        // Also honestly, who the fuck knows currently if smart playlists need updates. Just update them always
        // Every add to / remove from playlist type change (PlaylistManual) is handled by the above method
        // TODO But maybe add getters in the future, maybe at least wager if we have the POTENTIAL to have to be updated
        return playlist is PlaylistSmart || playlist is PlaylistCartesian
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
    
    func isTag(playlist: Playlist) -> Bool {
        return path(of: playlist).map { $0.objectID }.contains(tagPlaylist.objectID) && playlist.objectID != tagPlaylist.objectID
    }
    
    func playlists(containing track: Track) -> [PlaylistManual] {
        return Array((track.containingPlaylists as Set).of(type: PlaylistManual.self))
//            .filter { !self.isTag(playlist: $0) }
    }

    // Editing

    func isPlaylist(playlist: PlaylistProtocol) -> Bool {
        guard let playlist = playlist as? Playlist else {
            return false
        }
        return playlist != tagPlaylist
    }
            
    // iTunes
    
    func findTrack(byITunesID: String) -> Track? {
        let request = NSFetchRequest<Track>(entityName: "Track")
        request.predicate = NSPredicate(format: "iTunesID == %@", byITunesID)
        return try! viewContext.fetch(request).first
    }
    
    func url(of playlist: Playlist, relativeTo: URL) -> URL {
        var url = relativeTo
        
        for component in Library.shared.path(of: playlist).dropLast().dropFirst() {
            url = url.appendingPathComponent(component.name.asFileName)
        }
        
        return url
    }
    
    // Visual
    
    func icon(of playlist: Playlist) -> NSImage {
        switch playlist {
        case tagPlaylist:
            return #imageLiteral(resourceName: "tag")
        default:
            return playlist.icon
        }
    }
    
    // Adding
    
    func initialAdd(track: Track, moveAction: Preferences.FileLocationOnAdd? = nil) {
        let moveAction = moveAction ?? .current
        
        if moveAction  == .copy || moveAction == .move {
            ViewController.shared.tasker.enqueue(task: MoveTrackToMediaLocation(track: track, copy: moveAction == .copy))
        }

    }
}

extension Library {
    func registerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: viewContext)
    }
    
    @IBAction func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
        
        for delete in deletes {
            if let track = delete as? Track {
                mediaLocation.delete(track: track)
            }
            
            if let playlist = delete as? Playlist {
                if playlist == masterPlaylist {
                    fatalError("Attempting to delete the Master Playlist!")
                }
            }
        }
        
        sanityChanged = true // No matter what changed
        _exportChanged = _exportChanged?.union(inserts.map { $0.objectID })
                                        .union(deletes.map { $0.objectID })
                                        .union(updates.map { $0.objectID })
    }
}
