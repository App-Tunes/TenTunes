//
//  TrackController+Updates.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension TrackController {
    func registerObservers() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: Library.shared.viewContext)
        
        observeTrackWord = [\UserDefaults.trackWordSingular, \UserDefaults.trackWordPlural].map {
            AppDelegate.defaults.observe($0) { (defaults, _) in
                self._trackCounter.stringValue = String(describe: self.history.count,
                                                        singular: defaults.trackWordSingular,
                                                        plural: defaults.trackWordPlural)
            }
        }
    }
    
    @IBAction func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let library = Library.shared
        
        let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()

        for update in updates {
            if let track = (update as? Track) ?? (update as? TrackVisuals)?.track {
                reload(track: track)
                
                if filterBar.isOpen {
                    // Recreate the filter, since may cache some stuff
                    desired.filter = filterController.rules.filter(in: Library.shared.viewContext)
                    // Don't re-sort since the user would rather do it on his own
                }
                
                if mode == .tracksList && library.isAffected(playlist: history.playlist, whenModifying: track) {
                    desired._changed = true
                }
            }
            
            if let playlist = update as? Playlist {
                // When deleting playlists the parent is updated since it loses a child
                if mode == .tracksList && library.isAffected(playlist: history.playlist, whenChanging: playlist) {
                    desired._changed = true
                }
                
                if mode == .title && library.isAffected(playlist: history.playlist, whenChanging: playlist) {
                    // TODO Don't delete specifically enqueued tracks and past tracks
                    let left = Set(history.playlist.tracksList)
                    history.filter { left.contains($0) }
                }
            }
        }
        
        let trackDeletes = deletes.of(type: Track.self)
        let trackInserts = inserts.of(type: Track.self)
        let trackUpdates = updates.of(type: Track.self)
        
        if trackInserts.count > 0 || trackUpdates.count > 0 || trackDeletes.count > 0 {
            // Modified library?
            if mode == .tracksList && (trackInserts.count > 0 || trackDeletes.count > 0 || history.playlist is PlaylistSmart) {
                // Honestly, this happens so rarely that it doesn't really matter what was actually changed. Just reload, man.
                desired._changed = true
            }
        }
    }
}
