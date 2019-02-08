//
//  ViewPreferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Preferences

class ViewPreferences: NSViewController, Preferenceable {
    var toolbarItemTitle: String = "View"
    var toolbarItemIcon: NSImage = NSImage(named: .colorPanel)!
    
    @IBOutlet var initialKeyDisplay: NSPopUpButton!
    @IBOutlet var waveformDisplay: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        PopupEnum<UserDefaults.InitialKeyDisplay>.bind(initialKeyDisplay, toUserDefaultsKey: UserDefaults.InitialKeyDisplay.key, with: [.camelot, .english, .german], by: { $0.rawValue }, title: { $0.title })
        PopupEnum<UserDefaults.WaveformDisplay>.bind(waveformDisplay, toUserDefaultsKey: UserDefaults.WaveformDisplay.key, with: [.bars, .rounded], by: { $0.rawValue }, title: { $0.title })
    }
    
}
