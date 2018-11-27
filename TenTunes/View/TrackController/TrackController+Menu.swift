//
//  TrackController+Menu.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

extension TrackController: NSUserInterfaceValidations {
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard let action = item.action else {
            return false
        }
        
        if action == #selector(delete as (AnyObject) -> Swift.Void) {
            return mode == .queue || (mode == .tracksList && ((history.playlist as? ModifiablePlaylist)?.supports(action: .delete) ?? false))
        }
        
        if action == #selector(performFindPanelAction) { return mode == .tracksList }
        if action == #selector(showInfo) { return true }
        
        return false
    }
    
    @IBAction func performFindPanelAction(_ sender: AnyObject) {
        filterBar.open()
        view.window?.makeFirstResponder(filterController._tokenField)
    }
    
    @IBAction func delete(_ sender: AnyObject) {
        remove(indices: Array(_tableView.selectedRowIndexes))
    }        
}

