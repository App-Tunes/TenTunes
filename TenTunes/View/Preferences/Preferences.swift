//
//  Preferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension UserDefaults {
    @objc dynamic var trackColumnsHidden: [String: Bool] {
        return dictionary(forKey: "trackColumnsHidden") as! [String: Bool]
    }
}
