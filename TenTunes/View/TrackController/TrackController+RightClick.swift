//
//  File.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

extension TrackController: NSTableViewContextSensitiveMenuDelegate, NSMenuItemValidation {
    func currentMenu(forTableView tableView: NSTableViewContextSensitiveMenu) -> NSMenu? {
        trackActions = TrackActions.create(.playlist(at: Array(tableView.contextualClickedRows), in: history))
        return trackActions?._menu
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Probably the main Application menu
        if menuItem.target !== self {
            return validateUserInterfaceItem(menuItem)
        }
        
        return false
    }
}
