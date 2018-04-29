//
//  PreferencesWindowController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.04.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

enum InitialKeyDisplay: String {
    static let key: String = "intialKeyDisplay"
    
    case german = "german", english = "english"
    
    var title: String {
        switch(self) {
        case .german: return "German"
        case .english: return "English"
        }
    }
    
    static var current: InitialKeyDisplay {
        return ((UserDefaults.standard.value(forKey: key) as? String) ?=> InitialKeyDisplay.init) ?? .german
    }
}

class PreferencesWindowController: NSWindowController {

    @IBOutlet var initialKeyDisplay: NSPopUpButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        PopupEnum<InitialKeyDisplay>.bind(initialKeyDisplay, toUserDefaultsKey: InitialKeyDisplay.key, with: [.german, .english], by: { $0.rawValue }, title: { $0.title })
    }
}
