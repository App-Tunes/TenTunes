//
//  PlaylistController+Updates.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension PlaylistController {
    func registerObservers() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: Library.shared.viewContext)
        notificationCenter.addObserver(self, selector: #selector(historyMoved), name: HistoryNotification.moved, object: history)
    }
    
    @IBAction func historyMoved(notification: NSNotification) {
        delegate?.playlistController(self, selectionDidChange: history.current.playlists(library: library!))
        
        _back.isEnabled = history.canGoBack
        _forwards.isEnabled = history.canGoForwards
        
        if #available(OSX 10.14, *) {
            _home.contentTintColor = history.current == .library ? .selectedMenuItemTextColor : nil
        }
    }
    
    @IBAction func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let library = Library.shared
        
        let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
        
        let playlistDeletes = deletes.of(type: Playlist.self)
        let playlistInserts = inserts.of(type: Playlist.self)
        let playlistUpdates = updates.of(type: Playlist.self)
        
        // Modified playlists?
        // Use while so we can use break to nope out lol
        while !playlistUpdates.isEmpty || !playlistDeletes.isEmpty || !playlistInserts.isEmpty {
            if !playlistInserts.isEmpty && playlistUpdates.uniqueElement == playlistInserts.uniqueElement?.parent {
                _outlineView.animateInsert(items: Array(playlistInserts)) {
                    guard let (parent, idx) = library.position(of: $0) else {
                        return nil
                    }
                    return (idx, parent == library.masterPlaylist ? nil : parent)
                }
                
                if let insertedPlaylist = playlistInserts.uniqueElement, library.isPlaylist(playlist: insertedPlaylist), insertedPlaylist.name.contains("Unnamed") {
                    // If the name contains "Unnamed" it's proooobably safe to say we should name it
                    select(playlist: insertedPlaylist, editTitle: true)
                }
                
                break
            }
            
            if !playlistDeletes.isEmpty && playlistUpdates.uniqueElement == playlistDeletes.uniqueElement?.parent {
                _outlineView.animateDelete(items: Array(deletes.of(type: Playlist.self)))
                break
            }
            
            let prevSelected = selectedPlaylists.map({ $0.1 }).uniqueElement
            
            // TODO Animate movement?
            // It's enough if we reload only updated ones since deletes / inserts are auto-reloaded
            _outlineView.reloadItems(playlistUpdates.map { $0 == library.masterPlaylist ? nil : $0 }, reloadChildren: true)
            
            if let prevSelected = prevSelected {
                select(playlist: prevSelected)
            }
            
            break
        }
        
        if !history.current.isValid {
            // Deleted our current playlist! :<
            selectLibrary(self)
        }
    }
}
