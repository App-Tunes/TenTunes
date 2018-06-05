//
//  ExportPlaylistsController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 05.06.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class ExportPlaylistsController: NSWindowController {

    @IBOutlet var _trackLibrary: NSPathControl!
    @IBOutlet var _destinationDirectory: NSPathControl!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func export(_ sender: Any) {
    }
}
