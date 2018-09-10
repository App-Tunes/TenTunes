//
//  WindowWarden.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class WindowWarden {
    static let shared = WindowWarden()
    
    let actions = ActionStubs()
    
    var insertionIndex: Int {
        return NSApp.windowsMenu!.indexOfItem(withRepresentedObject: self) + 1
    }

    @discardableResult
    func remember(window: NSWindow, as title: String? = nil, key: (String, NSEvent.ModifierFlags)? = nil, toggleable: Bool = false) -> NSMenuItem {
        let item = NSMenuItem()
        item.title = title ?? window.title
        
        if let (key, mask) = key {
            item.keyEquivalent = key
            item.keyEquivalentModifierMask = mask
        }

        if actions.stubs.isEmpty {
            let separator = NSMenuItem.separator()
            separator.representedObject = self
            NSApp.windowsMenu?.insertItem(separator, at: 2)
            
            NSApp.windowsMenu?.insertItem(NSMenuItem.separator(), at: 3)
        }
        
        actions.bind(item) { _ in
            if toggleable && window.isKeyWindow {
                window.performClose(self)
            }
            else {
                window.makeKeyAndOrderFront(self)
            }
        }
        
        NSApp.windowsMenu?.insertItem(item, at: insertionIndex + actions.stubs.count)
        window.isExcludedFromWindowsMenu = true

        return item
    }
}
