
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

        allTracks = PlaylistLibrary(context: viewContext)
        if !fetchMaster() {
            _masterPlaylist = PlaylistFolder(context: viewContext)
            _masterPlaylist.name = "Master Playlist"
            
            viewContext.insert(_masterPlaylist)
            try! viewContext.save()
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
    
    var allTracks: PlaylistLibrary!
    var _masterPlaylist: PlaylistFolder!
    var masterPlaylist: PlaylistFolder {
        return _masterPlaylist
    }
    
    var _exportChanged: Set<NSManagedObjectID>? = Set()
    var exportSemaphore = DispatchSemaphore(value: 1)

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

    func isPlaylist(playlist: PlaylistProtocol) -> Bool {
        return playlist is Playlist
    }

    func isEditable(playlist: PlaylistProtocol) -> Bool {
        return playlist is PlaylistManual
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
                if Preferences.AnalyzeNewTracks.current == .analyze {
                    ViewController.shared.tasker.enqueue(task: AnalyzeTrack(track: track))
                }
                
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
        
        _exportChanged = _exportChanged?.union(inserts.map { $0.objectID })
                                        .union(deletes.map { $0.objectID })
                                        .union(updates.map { $0.objectID })
    }
}
