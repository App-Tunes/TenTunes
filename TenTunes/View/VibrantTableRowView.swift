//
//  VibrantTableRowView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class VibrantTableRowView: NSTableRowView {

    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let selectionRect = NSInsetRect(self.bounds, 2.5, 2.5)
            
            if isEmphasized {
                NSColor(hue: 0.6, saturation: 0.8, brightness: 0.7, alpha: 0.6).setFill()
            }
            else {
                NSColor(hue: 0.6, saturation: 0.0, brightness: 0.7, alpha: 0.25).setFill()
            }
            
            let selectionPath = NSBezierPath(rect: selectionRect)
            selectionPath.fill()
        }
    }
}
