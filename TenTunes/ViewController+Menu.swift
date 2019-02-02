//
//  ViewController+Menu.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 02.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension ViewController: NSUserInterfaceValidations {
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard let action = item.action else {
            return false
        }
        
        if action == #selector(performFindEverywherePanelAction) { return true }
        
        if action == #selector(createPlaylist(_:)) { return true }
        if action == #selector(createSmartPlaylist(_:)) { return true }
        if action == #selector(createGroup(_:)) { return true }
        if action == #selector(createCartesianPlaylist(_:)) { return true }
        
        return false
    }
    
    @IBAction func performFindEverywherePanelAction(_ sender: AnyObject) {
        playlistController.selectLibrary(self)
        trackController.performFindPanelAction(self)
    }
    
    @IBAction func createPlaylist(_ sender: AnyObject) {
        playlistController.createPlaylist(sender)
    }
    
    @IBAction func createSmartPlaylist(_ sender: AnyObject) {
        playlistController.createSmartPlaylist(sender)
    }
    
    @IBAction func createGroup(_ sender: AnyObject) {
        playlistController.createGroup(sender)
    }
    
    @IBAction func createCartesianPlaylist(_ sender: AnyObject) {
        playlistController.createCartesianPlaylist(sender)
    }

    
}
