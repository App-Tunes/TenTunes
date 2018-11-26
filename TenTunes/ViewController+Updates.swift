//
//  ViewController+Updates.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

extension ViewController {
    func registerObservers() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: Library.shared.viewContext)
        
        coverImageObserver = UserDefaults.standard.observe(\.titleBarStylization, options: [.initial, .new]) { (defaults, change) in
            self._coverImage.alphaValue = CGFloat(change.newValue ?? 0)
        }
    }
    
    @IBAction func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let library = Library.shared
        
        let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()

        let trackDeletes = deletes.of(type: Track.self)
        let trackInserts = inserts.of(type: Track.self)
        let trackUpdates = updates.of(type: Track.self)
        
        if trackInserts.count > 0 || trackUpdates.count > 0 || trackDeletes.count > 0 {
            // Invalidate caches
            library._allAuthors = nil
            library._allAlbums = nil
            library._allGenres = nil
        }
        
        let playlistDeletes = deletes.of(type: Playlist.self)
        let playlistInserts = inserts.of(type: Playlist.self)
        let playlistUpdates = updates.of(type: Playlist.self)

        // Modified playlists?
        // Use while so we can use break to nope out lol
        while !playlistUpdates.isEmpty || !playlistDeletes.isEmpty || !playlistInserts.isEmpty {
            if !playlistInserts.isEmpty && playlistUpdates.uniqueElement == playlistInserts.uniqueElement?.parent {
                playlistController._outlineView.animateInsert(items: Array(playlistInserts)) {
                    guard let (parent, idx) = library.position(of: $0) else {
                        return nil
                    }
                    return (idx, parent == library.masterPlaylist ? nil : parent)
                }
                
                if let insertedPlaylist = playlistInserts.uniqueElement, library.isPlaylist(playlist: insertedPlaylist), insertedPlaylist.name.contains("Unnamed") {
                    // If the name contains "Unnamed" it's proooobably safe to say we should name it
                    playlistController.select(playlist: insertedPlaylist, editTitle: true)
                }
                
                break
            }
            
            if !playlistDeletes.isEmpty && playlistUpdates.uniqueElement == playlistDeletes.uniqueElement?.parent {
                playlistController._outlineView.animateDelete(items: Array(deletes.of(type: Playlist.self)))
                break
            }
                
            let prevSelected = playlistController.selectedPlaylists.map({ $0.1 }).uniqueElement
            
            // TODO Animate movement?
            // It's enough if we reload only updated ones since deletes / inserts are auto-reloaded
            playlistController._outlineView.reloadItems(playlistUpdates.map { $0 == library.masterPlaylist ? nil : $0 }, reloadChildren: true)
            
            if let prevSelected = prevSelected {
                playlistController.select(playlist: prevSelected)
            }

            break
        }

        
        if let viewingPlaylist = trackController.history.playlist as? Playlist, deletes.of(type: Playlist.self).contains(viewingPlaylist) {
            // Deleted our current playlist! :<
            trackController.history = PlayHistory(playlist: library.allTracks)
        }
    }
}
