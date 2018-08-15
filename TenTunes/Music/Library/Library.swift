
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

    init?(name: String, at: URL, create: Bool?) {
        let libraryURL = at.appendingPathComponent("Library")
        let storeURL = libraryURL.appendingPathComponent("library.sqlite")
        
        if let create = create, create == FileManager.default.fileExists(atPath: storeURL.path) {
            return nil
        }

        directory = at
        mediaLocation = MediaLocation(directory: directory.appendingPathComponent("Media"))

        super.init(name: name, managedObjectModel: NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: name, withExtension: "momd")!)!)
        
        if (try? FileManager.default.createDirectory(at: libraryURL, withIntermediateDirectories: true, attributes: nil)) == nil {
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
    
    var _allAuthors: Set<String>?
    var allAuthors: Set<String> {
        if _allAuthors == nil {
            _allAuthors = Set(allTracks.tracksList
                .compactMap({ track in track.author}) + [Track.unknownAuthor])
        }
        return _allAuthors!
    }
    
    var _allGenres: Set<String>?
    var allGenres: Set<String> {
        if _allGenres == nil {
            _allGenres = Set(allTracks.tracksList
                .compactMap({ track in track.genre }))
        }
        return _allGenres!
    }
    
    var _allAlbums: Set<Album>?
    var allAlbums: Set<Album> {
        if _allAlbums == nil {
            _allAlbums = Set(allTracks.tracksList
                .map { track in Album(of: track) }
            )
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
    
    func isAffected(playlist: PlaylistProtocol, whenChanging: Playlist) -> Bool {
        if let playlist = playlist as? Playlist, path(of: whenChanging).contains(playlist) {
            return true
        }
        if playlist is PlaylistSmart {
            return true // TODO Only return true if actually affected (tags contain it or something)
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
    
    func isTag(playlist: Playlist) -> Bool {
        return path(of: playlist).contains(tagPlaylist) && playlist != tagPlaylist
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

    func isEditable(playlist: PlaylistProtocol) -> Bool {
        return playlist is PlaylistManual && isPlaylist(playlist: playlist)
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

        for insert in inserts {
            if let track = insert as? Track {
                if Preferences.FileLocationOnAdd.current == .copy || Preferences.FileLocationOnAdd.current == .move {
                    ViewController.shared.tasker.enqueue(task: MoveTrackToMediaLocation(track: track, copy: Preferences.FileLocationOnAdd.current == .copy))
                }
            }
        }
        
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
