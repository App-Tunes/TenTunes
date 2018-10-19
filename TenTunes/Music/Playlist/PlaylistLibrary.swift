//
//  PlaylistLibrary.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class PlaylistLibrary: PlaylistProtocol {
    var context: NSManagedObjectContext
    
    var _tracks: [Track]?
    
    required init(context: NSManagedObjectContext) {
        self.context = context
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: context)
    }
    
    @IBAction func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
        
        let trackDeletes = deletes.of(type: Track.self)
        
        // Modified library?
        if !inserts.of(type: Track.self).isEmpty {
            _tracks = nil
        }
        else if !trackDeletes.isEmpty {
            _tracks?.removeAll(elements: trackDeletes)
        }
    }
    
    func convert(to: NSManagedObjectContext) -> Self? {
        let converted = type(of: self).init(context: to)
        // Faster than executing a new fetch request
        // If not calculated yet DON'T run it since
        converted._tracks = _tracks ?=> to.compactConvert
        return converted
    }
    
    var childrenList: [Playlist]? {
        return nil
    }
    
    func loadTracks(force: Bool = false) {
        if force || _tracks == nil {
            let request: NSFetchRequest = Track.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            _tracks = try! context.fetch(request)
        }
    }
    
    var tracksList: [Track] {
        loadTracks()
        return _tracks!
    }
    
    var name: String {
        return "Library"
    }
}

extension PlaylistLibrary : ModifiablePlaylist {
    func _supports(action: ModifyingAction, rguard: RecursionGuard<Playlist>) -> Bool {
        // For track imports only
        return action == .add
    }
    
    func addTracks(_ tracks: [Track], above: Int?) {
        // Every track is already part of the library after import
        // And import is done automatically
    }
}
