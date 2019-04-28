//
//  File.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

extension TrackController: NSMenuDelegate, NSMenuItemValidation {
    func menuNeedsUpdate(_ menu: NSMenu) {
        trackActions = TrackActions.create(.playlist(at: _tableView.clickedRows, in: history))
        trackActions!.hijack(menu: menu)
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Probably the main Application menu
        if menuItem.target !== self {
            return validateUserInterfaceItem(menuItem)
        }
        
        return false
    }
}
