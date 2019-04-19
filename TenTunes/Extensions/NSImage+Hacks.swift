//
//  NSImage+Hacks.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension NSImage.Name {
    // Somehow these are missing in some build
    // TODO Remove when it's showing up again
    static let advancedName: NSImage.Name = "advanced"
    static let colorPanelName: NSImage.Name = "colorPanel"
    static let folderSmartName: NSImage.Name = "folderSmart"
}
