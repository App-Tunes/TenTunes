//
//  LibraryWindowController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class LibraryWindowController: NSWindowController {
    override func awakeFromNib() {
        window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
    }
    
    override func showWindow(_ sender: Any?) {
        NSApp.removeWindowsItem(window!) // Will be handled by custom items
    }
}

