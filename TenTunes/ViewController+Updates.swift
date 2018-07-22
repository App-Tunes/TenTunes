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
        
        let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
        
        for update in updates {
            // Modified track info?
            if let track = update as? Track {
                trackController.reload(track: track)
            }
            
            // Modified playlist contents?
            if let playlist = update as? Playlist {
                // When deleting playlists the parent is updated since it loses a child
                if Library.shared.isAffected(playlist: trackController.history.playlist, whenChanging: playlist) {
                    trackController.desired._changed = true
                }
                
                if let listening = player.history?.playlist, Library.shared.isAffected(playlist: listening, whenChanging: playlist) {
                    let left = Set(player.history!.playlist.tracksList)
                    player.history!.filter { left.contains($0) }
                }
            }
        }

        let trackDeletes = deletes.of(type: Track.self)
        let trackInserts = inserts.of(type: Track.self)
        let trackUpdates = updates.of(type: Track.self)
        
        if trackInserts.count > 0 || trackUpdates.count > 0 || trackDeletes.count > 0 {
            // Modified library?
            if trackInserts.count > 0 || trackDeletes.count > 0 {
                if trackController.history.playlist is PlaylistLibrary {
                    trackController.desired._changed = true
                }
            }

            // Invalidate caches
            Library.shared._allAuthors = nil
            Library.shared._allAlbums = nil
            Library.shared._allGenres = nil
        }
        
        let playlistDeletes = deletes.of(type: Playlist.self)
        let playlistInserts = inserts.of(type: Playlist.self)
        let playlistUpdates = updates.of(type: Playlist.self)

        // Modified playlists?
        if playlistDeletes.count > 0 && playlistUpdates.uniqueElement == playlistDeletes.uniqueElement?.parent {
            playlistController._outlineView.animateDelete(elements: Array(deletes.of(type: Playlist.self)))
        }
        else if playlistInserts.count > 0 && playlistUpdates.uniqueElement == playlistInserts.uniqueElement?.parent {
            playlistController._outlineView.animateInsert(elements: Array(inserts.of(type: Playlist.self))) {
                guard let (parent, idx) = Library.shared.position(of: $0) else {
                    return nil
                }
                return (idx, parent == Library.shared.masterPlaylist ? nil : parent)
            }
            
            if let insertedPlaylist = playlistInserts.uniqueElement, Library.shared.isPlaylist(playlist: insertedPlaylist) {
                // Let's hope that playlists don't get inserted other than when creating a new one, otherwise we need another solution
                playlistController.select(playlist: insertedPlaylist, editTitle: true)
            }
        }
        else if playlistUpdates.count > 0 || playlistDeletes.count > 0 || playlistInserts.count > 0 {
            let prevSelected = playlistController.selectedPlaylists.map({ $0.1 }).uniqueElement
            
            // TODO Only reload when the affected playlists are in view
            playlistController._outlineView.reloadData() // TODO Animate movement?
            
            if let prevSelected = prevSelected {
                playlistController.select(playlist: prevSelected)
            }
        }

        
        if let viewingPlaylist = trackController.history.playlist as? Playlist, deletes.of(type: Playlist.self).contains(viewingPlaylist) {
            
            // Deleted our current playlist! :<
            // TODO What to do when deleting listening playlist?
            trackController.history = PlayHistory(playlist: Library.shared.allTracks)
        }
    }
}
