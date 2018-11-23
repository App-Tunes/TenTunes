//
//  PreferencesWindowController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.04.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension UserDefaults {
    @objc dynamic var titleBarStylization: Double {
        return double(forKey: "titleBarStylization")
    }
    
    @objc dynamic var waveformDisplay: String? {
        return string(forKey: Preferences.WaveformDisplay.key)
    }
    
    @objc dynamic var trackColumnsHidden: [String: Bool] {
        return dictionary(forKey: "trackColumnsHidden") as! [String: Bool]
    }
}

class Preferences {
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
    
    enum AnimateWaveformTransitions {
        static let key: String = "animateWaveformTransitions"
        
        case animate, dont
        
        static var current: AnimateWaveformTransitions {
            return UserDefaults.standard.bool(forKey: key) ? animate : dont
        }
    }
    
    enum AnimateWaveformAnalysis {
        static let key: String = "animateWaveformAnalysis"
        
        case animate, dont
        
        static var current: AnimateWaveformAnalysis {
            return UserDefaults.standard.bool(forKey: key) ? animate : dont
        }
    }
    
    enum PreviewWaveformAnalysis {
        static let key: String = "previewWaveformAnalysis"
        
        case preview, dont
        
        static var current: PreviewWaveformAnalysis {
            return UserDefaults.standard.bool(forKey: key) ? preview : dont
        }
    }
    
    enum WaveformDisplay: String {
        static let key: String = "waveformDisplay"
        
        case bars = "bars", rounded = "hill"
        
        var title: String {
            switch(self) {
            case .bars: return "Bars"
            case .rounded: return "Rounded"
            }
        }
        
        static var current: WaveformDisplay {
            return ((UserDefaults.standard.value(forKey: key) as? String) ?=> WaveformDisplay.init) ?? .bars
        }
    }
    
    enum AnalyzeNewTracks {
        static let key: String = "autoAnalyzeTracksOnAdd"
        
        case analyze, dont
        
        static var current: AnalyzeNewTracks {
            return UserDefaults.standard.bool(forKey: key) ? analyze : dont
        }
    }
    
    enum FileLocationOnAdd: String {
        static let key: String = "fileLocationOnAdd"
        
        case link = "link", copy = "copy", move = "move"
        
        var title: String {
            switch(self) {
            case .link: return "Link to the file"
            case .copy: return "Copy to Media Directory"
            case .move: return "Move to Media Directory"
            }
        }
        
        static var current: FileLocationOnAdd {
            return ((UserDefaults.standard.value(forKey: key) as? String) ?=> FileLocationOnAdd.init) ?? .copy
        }
    }
    
    enum PlayOpenedFiles {
        static let key: String = "autoPlayTracksOnOpen"
        
        case play, dont
        
        static var current: PlayOpenedFiles {
            return UserDefaults.standard.bool(forKey: key) ? play : dont
        }
    }
    
    enum EditingTrackUpdatesAlbum {
        static let key: String = "updatingTrackUpdatesAlbum"
        
        case update, dont
        
        static var current: EditingTrackUpdatesAlbum {
            return UserDefaults.standard.bool(forKey: key) ? update : dont
        }
    }
}

class PreferencesWindowController: NSWindowController {

    @IBOutlet var initialKeyDisplay: NSPopUpButton!
    
    @IBOutlet var waveformDisplay: NSPopUpButton!

    @IBOutlet var fileLocationOnAdd: NSPopUpButton!

    override func windowDidLoad() {
        super.windowDidLoad()

        PopupEnum<Preferences.InitialKeyDisplay>.bind(initialKeyDisplay, toUserDefaultsKey: Preferences.InitialKeyDisplay.key, with: [.camelot, .english, .german], by: { $0.rawValue }, title: { $0.title })
        PopupEnum<Preferences.WaveformDisplay>.bind(waveformDisplay, toUserDefaultsKey: Preferences.WaveformDisplay.key, with: [.bars, .rounded], by: { $0.rawValue }, title: { $0.title })
        PopupEnum<Preferences.FileLocationOnAdd>.bind(fileLocationOnAdd, toUserDefaultsKey: Preferences.FileLocationOnAdd.key, with: [.copy, .move, .link], by: { $0.rawValue }, title: { $0.title })
    }
}
