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
        let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
        
        // Modified library?
        if inserts.of(type: Track.self).count > 0 || updates.of(type: Track.self).count > 0 || deletes.of(type: Track.self).count > 0 {
            _tracks = nil
        }
    }
    
    func convert(to: NSManagedObjectContext) -> Self {
        return type(of: self).init(context: to)
    }
    
    var childrenList: [Playlist]? {
        return nil
    }
    
    var tracksList: [Track] {
        if _tracks == nil {
            let request: NSFetchRequest = Track.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            _tracks = try! context.fetch(request)
        }
        
        return _tracks!
    }
}
