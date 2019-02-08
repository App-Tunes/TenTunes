//
//  ViewPreferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Preferences

extension UserDefaults {
    @objc dynamic var titleBarStylization: Double {
        return double(forKey: "titleBarStylization")
    }
    
    enum InitialKeyDisplay: String {
        static let key: String = "intialKeyDisplay"
        
        case openKey = "openKey", camelot = "camelot", english = "english", german = "german"
        
        var title: String {
            switch(self) {
            case .german: return "German"
            case .camelot: return "Camelot"
            case .openKey: return "Open Key"
            case .english: return "English"
            }
        }
    }
    
    var initialKeyDisplay: InitialKeyDisplay {
        return (string(forKey: InitialKeyDisplay.key) ?=> InitialKeyDisplay.init) ?? .openKey
    }
    
    enum AnimateWaveformTransitions {
        static let key: String = "animateWaveformTransitions"
        case animate, dont
    }
    
    var animateWaveformTransitions: AnimateWaveformTransitions {
        return bool(forKey: AnimateWaveformTransitions.key) ? .animate : .dont
    }
    
    enum AnimateWaveformAnalysis {
        static let key: String = "animateWaveformAnalysis"
        case animate, dont
    }
    
    var animateWaveformAnalysis: AnimateWaveformAnalysis {
        return bool(forKey: AnimateWaveformAnalysis.key) ? .animate : .dont
    }
    
    enum PreviewWaveformAnalysis {
        static let key: String = "previewWaveformAnalysis"
        case preview, dont
    }
    
    var previewWaveformAnalysis: PreviewWaveformAnalysis {
        return bool(forKey: PreviewWaveformAnalysis.key) ? .preview : .dont
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
    }
    
    // observable hack
    @objc dynamic var waveformDisplay: NSString? { return string(forKey: WaveformDisplay.key) as NSString? }
    
    var _waveformDisplay: WaveformDisplay {
        return (string(forKey: WaveformDisplay.key) ?=> WaveformDisplay.init) ?? .bars
    }
    
    var trackCombinedTitleSource: Bool {
        return bool(forKey: "trackCombinedTitleSource")
    }
    
    var trackSmallRows: Bool {
        return bool(forKey: "trackSmallRows")
    }    
}

class ViewPreferences: NSViewController, Preferenceable {
    var toolbarItemTitle: String = "View"
    var toolbarItemIcon: NSImage = NSImage(named: .colorPanel)!
    
    @IBOutlet var initialKeyDisplay: NSPopUpButton!
    @IBOutlet var waveformDisplay: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        PopupEnum<UserDefaults.InitialKeyDisplay>.bind(initialKeyDisplay, toUserDefaultsKey: UserDefaults.InitialKeyDisplay.key, with: [.openKey, .camelot, .english, .german], by: { $0.rawValue }, title: { $0.title })
        PopupEnum<UserDefaults.WaveformDisplay>.bind(waveformDisplay, toUserDefaultsKey: UserDefaults.WaveformDisplay.key, with: [.bars, .rounded], by: { $0.rawValue }, title: { $0.title })
    }
    
}
