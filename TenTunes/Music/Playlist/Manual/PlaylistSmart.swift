//
//  PlaylistSmart+CoreDataClass.swift
//  
//
//  Created by Lukas Tenbrink on 19.07.18.
//
//

import Foundation
import CoreData

@objc(PlaylistSmart)
public class PlaylistSmart: Playlist {
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: context)
    }
    
    @IBAction func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
        
        // Modified library?
        if !inserts.isEmpty || !updates.isEmpty || !deletes.isEmpty {
            _tracksList = nil
        }
    }
    
    var _tracksList: [Track]?
    
    override var tracksList: [Track] {
        get {
            if _tracksList == nil {
                let all = Library.shared.allTracks.convert(to: managedObjectContext!)!.tracksList
                _tracksList = all.filter(filter(in: managedObjectContext!))
            }
            
            return _tracksList!
        }
    }
        
    func filter(in context: NSManagedObjectContext) -> (Track) -> Bool {
        return rrules.filter(in: context)
    }
    
    override var icon: NSImage {
        return #imageLiteral(resourceName: "playlist-smart")
    }
}
