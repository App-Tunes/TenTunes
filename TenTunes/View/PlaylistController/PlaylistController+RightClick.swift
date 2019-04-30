//
//  PlaylistController+RightClick.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

extension PlaylistController : NSOutlineViewContextSensitiveMenuDelegate {
    func currentMenu(forOutlineView outlineView: NSOutlineViewContextSensitiveMenu) -> NSMenu? {
        guard let items = outlineView.contextualClickedRows.compactMap(_outlineView.item) as? [Item] else {
            return nil
        }
        
        guard let playlists = (items.map { $0.asPlaylist }) as? [Playlist] else {
            return nil
        }
        
        playlistActions = PlaylistActions.create(.visible(playlists: playlists))
        return playlistActions?.menu()
    }
}

extension PlaylistController: NSMenuDelegate, NSMenuItemValidation {
    var menuItems: [Item] {
        return _outlineView.contextualClickedRows.compactMap { _outlineView.item(atRow: $0) as? Item }
    }
    
    var menuPlaylists: [Playlist] {
        return menuItems.compactMap { $0.asPlaylist }
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Probably the main Application menu
        if menuItem.target !== self {
            return validateUserInterfaceItem(menuItem)
        }
        
        return true
    }
}

