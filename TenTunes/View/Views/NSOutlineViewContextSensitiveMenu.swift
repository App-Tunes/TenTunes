//
//  NSOutlineView+ContextSensitiveMenu.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 01.12.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol NSOutlineViewContextSensitiveMenuDelegate {
    func outlineView(_ outlineView: NSOutlineView, menuForItem item: Any?) -> NSMenu?
}

class NSOutlineViewContextSensitiveMenu : NSOutlineView {
    override func menu(for event: NSEvent) -> NSMenu? {
        let location = convert(event.locationInWindow, from: nil)
        let item = self.item(atRow: row(at: location))
        return (delegate as? NSOutlineViewContextSensitiveMenuDelegate)?.outlineView(self, menuForItem: item) ?? super.menu(for: event)
    }
}
