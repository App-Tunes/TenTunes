//
//  WelcomeWindowController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class WelcomeWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func switchCasualUser(_ sender: Any) {
        window!.close()
        
        (NSApp.delegate as! AppDelegate).commenceAfterWelcome()
    }
    
    @IBAction func switchDJ(_ sender: Any) {
        window!.close()

        AppDelegate.defaults[.trackWordSingular] = "track"
        AppDelegate.defaults[.trackWordPlural] = "tracks"
        AppDelegate.defaults[.keepFilterBetweenPlaylists] = true
        AppDelegate.defaults[.quantizedJump] = true
        AppDelegate.defaults[.initialKeyWrite] = .openKey
        AppDelegate.defaults[.trackColumnsHidden] = [
            "albumColumn": true,
            "authorColumn": true,
        ]

        (NSApp.delegate as! AppDelegate).commenceAfterWelcome()
    }
}
