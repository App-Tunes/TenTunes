//
//  Defaults.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 09.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Defaults

extension UserDefaults {
    static var swifty: Defaults {
        return defaults
    }
    
    func consume(toggle: String) -> Bool {
        let consumed = bool(forKey: toggle)
        if !consumed { set(true, forKey: toggle) }
        return !consumed
    }
}
