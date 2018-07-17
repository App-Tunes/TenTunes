//
//  PlaylistController+RightClick.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

extension PlaylistController: NSMenuDelegate {
    var menuPlaylists: [Playlist] {
        return _outlineView.clickedRows.compactMap { _outlineView.item(atRow: $0) as? Playlist }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        if menuPlaylists.count < 1 {
            menu.cancelTrackingWithoutAnimation()
        }
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Probably the main Application menu
        if menuItem.target !== self {
            return validateUserInterfaceItem(menuItem)
        }
        
        return true
    }
    
    @IBAction func duplicatePlaylist(_ sender: Any) {
        for playlist in menuPlaylists {
            let copy = playlist.duplicate(except: ["id", "creationDate", "parent"], deep: ["children"]) as! Playlist
            let idx = playlist.parent!.children.index(of: playlist)
            
            playlist.parent!.addPlaylist(copy, above: idx)
        }
        
        try! Library.shared.viewContext.save()
    }
    
    @IBAction func deletePlaylist(_ sender: Any) {
        let playlistRows = _outlineView.clickedRows
        let message = "Are you sure you want to delete \(playlistRows.count) playlist\(playlistRows.count > 1 ? "s" : "")?"
        if NSAlert.confirm(action: "Delete Playlists", text: message) {
            delete(indices: playlistRows)
        }
    }
}
