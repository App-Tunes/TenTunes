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
            return isQueue || Library.shared.isEditable(playlist: history.playlist)
        }
        
        if action == #selector(performFindPanelAction) { return !isQueue }
        if action == #selector(showInfo) { return true }
        
        return false
    }
    
    @IBAction func performFindPanelAction(_ sender: AnyObject) {        
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _searchBarHeight.animator().constant = CGFloat(26)
        })
        _searchField.window?.makeFirstResponder(_searchField)
    }
    
    @IBAction func delete(_ sender: AnyObject) {
        remove(indices: Array(_tableView.selectedRowIndexes))
    }
        
    @IBAction func closeSearchBar(_ sender: Any) {
        desired.filter = nil
        
        _searchField.resignFirstResponder()
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _searchBarHeight.animator().constant = CGFloat(0)
        })
        view.window?.makeFirstResponder(view)
    }
}

