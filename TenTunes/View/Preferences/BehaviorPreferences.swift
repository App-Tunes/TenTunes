//
//  BehaviorPreferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Preferences

class BehaviorPreferences: NSViewController, Preferenceable {
    var toolbarItemTitle: String = "Behavior"
    var toolbarItemIcon: NSImage = NSImage(named: .advanced)!

    @IBOutlet var fileLocationOnAdd: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        PopupEnum<UserDefaults.FileLocationOnAdd>.bind(fileLocationOnAdd, toUserDefaultsKey: UserDefaults.FileLocationOnAdd.key, with: [.copy, .move, .link], by: { $0.rawValue }, title: { $0.title })
    }
    
}
