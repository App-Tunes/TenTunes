
//
//  Library.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import CoreData
import Defaults

class Library : NSPersistentContainer {
    static let libraryFolderName = "Library.ttl"
    
    static var shared: Library {
        return async! // In main thread, it's always there
    }
    
    static var async: Library? {
        return (NSApp.delegate as? AppDelegate)?.persistentContainer
    }
    
    init?(name: String, at url: URL, create: Bool?) {
        directory = url.pathExtension == "ttl" ? url.deletingLastPathComponent() : url

        let libraryURL = directory.appendingPathComponent(Library.libraryFolderName)
        let storeURL = libraryURL.appendingPathComponent("library.sqlite")
        
        if let create = create, create == FileManager.default.fileExists(atPath: storeURL.path) {
            return nil
        }

        mediaLocation = MediaLocation(directory: directory.appendingPathComponent("Media"))

        super.init(name: name, managedObjectModel: AppDelegate.objectModel)
        
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
        
        setSpecial(for: PlaylistRole.library, to: PlaylistLibrary(context: viewContext))
        setSpecial(for: PlaylistRole.master, to: fetchCreateSpecialFolder(key: "Master Playlist") { playlist in
            playlist.name = "Master Playlist"
        })
        setSpecial(for: PlaylistRole.playlists, to: fetchCreateSpecialFolder(key: "Super Playlist") { playlist in
            playlist.name = "Playlists"
            self[PlaylistRole.master].addToChildren(playlist)
        })
        setSpecial(for: PlaylistRole.tags, to: fetchCreateSpecialFolder(key: "Tag Playlist") { playlist in
            playlist.name = "Tags"
            self[PlaylistRole.master].addToChildren(playlist)
        })
    }
    
    func fetchCreateSpecialFolder(key: String, create: (PlaylistFolder) -> Swift.Void) -> PlaylistFolder {
        if let url = defaultMetadata[key], let playlist = self.import().playlist(id: url) as? PlaylistFolder {
            return playlist
        }
        else {
            let playlist = PlaylistFolder(context: viewContext)
            
            create(playlist)
            
            viewContext.insert(playlist)
            try! viewContext.save()
            
            // Need to do this after initial save, otherwise the ID is temporary.............
            defaultMetadata[key] = export().stringID(of: playlist)
            try! viewContext.save()
            
            return playlist
        }
    }
    
    var directory: URL
    var mediaLocation: MediaLocation
    
    var _roleDict = [Int: AnyObject]()
    var _roleDictReverse = [UUID: AnyObject]()

    var sanityChanged = true
    var sanitySemaphore = DispatchSemaphore(value: 1)

    var _exportChanged: Set<NSManagedObjectID>? = Set()
    var exportSemaphore = DispatchSemaphore(value: 1)
    
    func allTracks(in context: NSManagedObjectContext? = nil) -> [Track] {
        return self[PlaylistRole.library, in: context].tracksList
    }
    
    var _allAuthors: Set<Artist>?
    var allAuthors: Set<Artist> {
        if _allAuthors == nil {
            _allAuthors = Set(allTracks().flatMap { $0.authors })
        }
        return _allAuthors!
    }
    
    var _allGenres: Set<String>?
    var allGenres: Set<String> {
        if _allGenres == nil {
            _allGenres = Set(allTracks().compactMap { $0.genre })
        }
        return _allGenres!
    }
    
    var _allAlbums: Set<Album>?
    var allAlbums: Set<Album> {
        if _allAlbums == nil {
            _allAlbums = Set(allTracks().compactMap { $0.rAlbum })
        }
        return _allAlbums!
    }
    
    static func defaultURL() -> URL {        
        return MediaLocation.musicDirectory!.appendingPathComponent("Ten Tunes")
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
    
    subscript<Type>(_ role: LibraryRole<Type>) -> Type {
        return self[role, in: nil]
    }
    
    subscript<Type>(_ role: LibraryRole<Type>, in context: NSManagedObjectContext?) -> Type {
        return (_roleDict[role.index] as! AnyPlaylist).convert(to: context ?? viewContext)! as! Type
    }
    
    func role<Type : AnyPlaylist>(of: Type) -> AnyObject? {
        return _roleDictReverse[of.persistentID]
    }
    
    func allPlaylists(in context: NSManagedObjectContext? = nil) -> [Playlist] {
        let context = context ?? viewContext
        return try! context.fetch(NSFetchRequest<Playlist>(entityName: "Playlist"))
    }
    
    func allTags(in context: NSManagedObjectContext? = nil) -> [Playlist] {
        // TODO Instead only use all children method of tagPlaylist
        return allPlaylists(in: context).filter { self.isTag(playlist: $0) }
    }
    
    func isAffected(playlist: AnyPlaylist, whenChanging: Playlist) -> Bool {
        if let playlist = playlist as? Playlist, whenChanging == playlist {
            return true
        }
        
        if let playlist = playlist as? PlaylistFolder, whenChanging.path.contains(playlist) {
            return true
        }
        
        if playlist is PlaylistSmart || playlist is PlaylistCartesian {
            return true // TODO Only return true if actually affected (tags contain it or something)
        }
        
        return false
    }
    
    func isAffected(playlist: AnyPlaylist, whenModifying: Track) -> Bool {
        // Also honestly, who the fuck knows currently if smart playlists need updates. Just update them always
        // Every add to / remove from playlist type change (PlaylistManual) is handled by the above method
        // TODO But maybe add getters in the future, maybe at least wager if we have the POTENTIAL to have to be updated
        return playlist is PlaylistSmart || playlist is PlaylistCartesian
    }

    func position(of: Playlist) -> (PlaylistFolder, Int)? {
        if let parent = of.parent {
            return (parent, parent.childrenList.firstIndex(of: of)!)
        }
        return nil
    }
    
    func isTag(playlist: Playlist) -> Bool {
        let tagsID = self[PlaylistRole.tags].objectID
        return playlist.path.map { $0.objectID }.contains(tagsID) && playlist.objectID != tagsID
    }
    
    func playlists(containing track: Track) -> [PlaylistManual] {
        return Array((track.containingPlaylists as Set).of(type: PlaylistManual.self))
            .filter { !self.isTag(playlist: $0) }
    }

    // Editing

    func isPlaylist(playlist: AnyPlaylist) -> Bool {
        guard let playlist = playlist as? Playlist else {
            return false
        }
        return role(of: playlist) == nil
    }
            
    // iTunes
    
    func findTrack(byITunesID: String) -> Track? {
        let request = NSFetchRequest<Track>(entityName: "Track")
        request.predicate = NSPredicate(format: "iTunesID == %@", byITunesID)
        return try! viewContext.fetch(request).first
    }
    
    func url(of playlist: Playlist, relativeTo: URL) -> URL {
        var url = relativeTo
        
        for component in playlist.path.dropLast().dropFirst() {
            url = url.appendingPathComponent(component.name.asFileName)
        }
        
        return url
    }
    
    // Visual
    
    func icon<Type: AnyPlaylist>(of playlist: Type) -> NSImage {
        let role = self.role(of: playlist)
        
        if role === PlaylistRole.tags {
            return #imageLiteral(resourceName: "tag")
        }
        else if role === PlaylistRole.playlists {
            return NSImage(named: .musicName)!
        }

        return playlist.icon
    }
    
    // Adding
    
    func initialAdd(track: Track, moveAction: Defaults.Keys.FileLocationOnAdd? = nil) {
        let moveAction = moveAction ?? AppDelegate.defaults[.fileLocationOnAdd]
        
        // TODO Bit hacky to test if we're shared library
        if moveAction  == .copy || moveAction == .move, self == Library.shared {
            ViewController.shared.tasker.enqueue(task: MoveTrackToMediaLocation(track: track, copy: moveAction == .copy))
        }
    }
    
    private func setSpecial<Type: AnyPlaylist>(for role: LibraryRole<Type>, to: Type) {
        self._roleDict[role.index] = to as AnyObject
        self._roleDictReverse[to.persistentID] = role
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
                if playlist == self[PlaylistRole.master] {
                    fatalError("Attempting to delete the Master Playlist!")
                }
            }
        }
        
        sanityChanged = true // No matter what changed
        _exportChanged = _exportChanged?.union(inserts.map { $0.objectID })
                                        .union(deletes.map { $0.objectID })
                                        .union(updates.map { $0.objectID })
        
        let trackDeletes = deletes.of(type: Track.self)
        let trackInserts = inserts.of(type: Track.self)
        let trackUpdates = updates.of(type: Track.self)
        
        if trackInserts.count > 0 || trackUpdates.count > 0 || trackDeletes.count > 0 {
            // Invalidate caches
            _allAuthors = nil
            _allAlbums = nil
            _allGenres = nil
        }
    }
}

class LibraryRole<Type> {
    let index: Int
    
    init(_ index: Int) {
        self.index = index
    }
}

class PlaylistRole {
    static let library = LibraryRole<PlaylistLibrary>(0)
    static let master = LibraryRole<PlaylistFolder>(1)
    
    static let playlists = LibraryRole<PlaylistFolder>(2)
    static let tags = LibraryRole<PlaylistFolder>(3)
}
