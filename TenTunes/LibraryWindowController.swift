//
//  LibraryWindowController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class LibraryWindowController: NSWindowController {
    static let xOffsetStandardButtons: CGFloat = 0
    static let yOffsetStandardButtons: CGFloat = 7

    override func awakeFromNib() {
        window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
    }
    
    override func showWindow(_ sender: Any?) {
        NSApp.removeWindowsItem(window!) // Will be handled by custom items
    }
    
    
}

extension LibraryWindowController : NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        relocateStandardButtons()
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        relocateStandardButtons()
    }
    
    func windowDidEnterFullScreen(_ notification: Notification) {
        relocateStandardButtons()
    }
    
    func relocateStandardButtons() {
        window!.moveStandardButtons(x: LibraryWindowController.xOffsetStandardButtons, y: LibraryWindowController.yOffsetStandardButtons)
        
        (contentViewController as! ViewController)._playLeftConstraint.animator().constant = window!.styleMask.contains(.fullScreen) ? 20 : 75
    }
}
