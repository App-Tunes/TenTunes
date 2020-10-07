//
//  AppDelegate+Menu.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 15.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension AppDelegate: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // If not, we aren't ready
        return ViewController.shared != nil
    }
    
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
        preferencesController.show()
    }
    
    @IBAction
    func switchLibrary(sender: Any?) {
        let task = Process()

        task.launchPath = "/bin/sh"
        task.arguments = [
            "-c",
            "sleep 0.2; open \"\(Bundle.main.bundlePath)\" --args --no-reopen"
        ]
        terminateProcess = task
        
        NSApplication.shared.terminate(nil)
        // If terminate later, relaunch process is ready still
    }
    
    @IBAction
    func refreshMetadata(sender: Any?) {
        for track in Library.shared.allTracks() {
            track.metadataFetchDate = nil
        }
        
        try! Library.shared.viewContext.save()
    }
}
