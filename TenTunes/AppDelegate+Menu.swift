//
//  AppDelegate+Menu.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 15.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension AppDelegate {
    @IBAction func revealExports(_ sender: Any) {
        NSWorkspace.shared.activateFileViewerSelecting([Library.shared.export().url(title: nil)])
    }
    
    @IBAction func refreshExports(_ sender: Any) {
        Library.shared._exportChanged = nil
    }
    
    @IBAction func exportPlaylists(_ sender: Any) {
        exportPlaylistsController.showWindow(self)
    }
    
    @IBAction
    func showPreferences(sender: Any?) {
        if !(preferencesController.window?.isVisible ?? false) {
            preferencesController.window?.center()
        }
        preferencesController.showWindow(self)
    }
    
    @IBAction
    func refreshMetadata(sender: Any?) {
        for track in Library.shared.allTracks() {
            track.metadataFetchDate = nil
        }
        
        try! Library.shared.viewContext.save()
    }
}
