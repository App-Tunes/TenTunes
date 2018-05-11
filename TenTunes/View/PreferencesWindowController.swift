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
    
    case camelot = "camelot", english = "english", german = "german"
    
    var title: String {
        switch(self) {
        case .german: return "German"
        case .camelot: return "Camelot"
        case .english: return "English"
        }
    }
    
    static var current: InitialKeyDisplay {
        return ((UserDefaults.standard.value(forKey: key) as? String) ?=> InitialKeyDisplay.init) ?? .camelot
    }
}

enum WaveformAnimation: String {
    static let key: String = "waveformAnimation"
    
    case everything = "everything", nothing = "nothing"
    
    var title: String {
        switch(self) {
        case .everything: return "Fully Animated"
        case .nothing: return "Unanimated"
        }
    }
    
    static var current: WaveformAnimation {
        return ((UserDefaults.standard.value(forKey: key) as? String) ?=> WaveformAnimation.init) ?? .everything
    }
}

enum AnalyzeNewTracks {
    static let key: String = "dontAutoAnalyzeTracksOnAdd"
    
    case analyze, dont
    
    static var current: AnalyzeNewTracks {
        return UserDefaults.standard.bool(forKey: key) ? dont : analyze
    }
}

enum PlayOpenedFiles {
    static let key: String = "dontAutoPlayTracksOnOpen"
    
    case play, dont
    
    static var current: PlayOpenedFiles {
        return UserDefaults.standard.bool(forKey: key) ? dont : play
    }
}

class PreferencesWindowController: NSWindowController {

    @IBOutlet var initialKeyDisplay: NSPopUpButton!
    
    @IBOutlet var waveformAnimation: NSPopUpButton!

    override func windowDidLoad() {
        super.windowDidLoad()

        PopupEnum<InitialKeyDisplay>.bind(initialKeyDisplay, toUserDefaultsKey: InitialKeyDisplay.key, with: [.camelot, .english, .german], by: { $0.rawValue }, title: { $0.title })
        PopupEnum<WaveformAnimation>.bind(waveformAnimation, toUserDefaultsKey: WaveformAnimation.key, with: [.everything, .nothing], by: { $0.rawValue }, title: { $0.title })
    }
}
