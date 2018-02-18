//
//  Keycodes.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 18.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

enum Keycodes: Int {
    case returnKey = 36, enterKey = 76
    
    func matches(event: NSEvent) -> Bool {
        return event.keyCode == UInt16(self.rawValue)
    }
}
