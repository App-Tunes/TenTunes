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
        
        menu.item(withAction: #selector(deletePlaylist(_:)))?.isVisible = menuPlaylists.map(Library.shared.isPlaylist).allMatch { $0 }
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
        delete(indices: _outlineView.clickedRows)
    }
}
