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
    case delete = 51, forwardDelete = 117
    
    struct Either {
        static let enter = Either([Keycodes.returnKey, Keycodes.enterKey])
        static let delete = Either([Keycodes.delete, Keycodes.forwardDelete])
        
        let codes: [Keycodes]
        
        init(_ codes: [Keycodes]) {
            self.codes = codes
        }
        
        func matches(event: NSEvent) -> Bool {
            return codes.anyMatch { $0.matches(event: event) }
        }
    }

    func matches(event: NSEvent) -> Bool {
        return event.keyCode == UInt16(self.rawValue)
    }
}
