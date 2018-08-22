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
            return mode == .queue || (mode == .tracksList && Library.shared.isEditable(playlist: history.playlist))
        }
        
        if action == #selector(performFindPanelAction) { return mode == .tracksList }
        if action == #selector(showInfo) { return true }
        
        return false
    }
    
    @IBAction func performFindPanelAction(_ sender: AnyObject) {
        openFindPanel()
        view.window?.makeFirstResponder(filterController._labelField)
    }
    
    func openFindPanel() {
        filterBar.open()
        filterController._labelField.notifyTokenChange() // Get our initial filter on
    }
    
    @IBAction func delete(_ sender: AnyObject) {
        remove(indices: Array(_tableView.selectedRowIndexes))
    }        
}

