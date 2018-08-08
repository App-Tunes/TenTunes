//
//  UnscalingMenu.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.08.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class UnscalingMenu: NSMenu {
    override func awakeFromNib() {
        super.awakeFromNib()
        resizeImages()
    }
}
