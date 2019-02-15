//
//  Playlist+CoreDataClass.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Playlist)
public class Playlist: NSManagedObject, AnyPlaylist {
    
    static let pasteboardType = NSPasteboard.PasteboardType(rawValue: "tentunes.playlist")

    func convert(to: NSManagedObjectContext) -> Self? {
        return to.convert(self)
    }
    
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
    
    var persistentID: UUID {
        return id
    }
    
    var _tracksList: [Track]?
    func _freshTracksList(rguard: RecursionGuard<Playlist>) -> [Track] {
        return []
    }
    
    func guardedTracksList(rguard: RecursionGuard<Playlist>) -> [Track] {
        if _tracksList == nil {
            _tracksList = _freshTracksList(rguard: rguard)
        }
        
        return _tracksList!
    }

    var tracksList: [Track] {
        return guardedTracksList(rguard: RecursionGuard())
    }

    func track(at: Int) -> Track? {
        return tracksList[at]
    }
    
    var size: Int {
        return tracksList.count
    }
    
    func duplicate(into: NSManagedObjectContext? = nil) -> Playlist {
        return duplicate(
            except: ["id", "creationDate", "parent"],
            deep: ["children"],
            into: into
            ) as! Playlist
    }
    
    var isTrivial: Bool { return false }

    var icon: NSImage {
        return #imageLiteral(resourceName: "playlist")
    }
}
