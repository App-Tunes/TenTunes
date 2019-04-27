//
//  StylerMyler.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class StylerMyler {
    static func makeRoundRect(_ view: NSView) {
        view.wantsLayer = true
        view.layer!.borderWidth = 1.0
        view.layer!.borderColor = NSColor.lightGray.cgColor.copy(alpha: CGFloat(0.333))
        view.layer!.cornerRadius = 3.0
        view.layer!.masksToBounds = true
    }
}
