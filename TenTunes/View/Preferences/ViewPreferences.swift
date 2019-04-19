//
//  ViewPreferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Preferences

import Defaults

extension Defaults.Keys {
    static let titleBarStylization = Key<Double>("titleBarStylization", default: 0.5)
    
    enum InitialKeyDisplay: String, Codable {
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

    static let initialKeyDisplay = Key<InitialKeyDisplay>("initialKeyDisplay", default: .english)
    static let animateWaveformTransitions = Key<Bool>("animateWaveformTransitions", default: true)
    static let animateWaveformAnalysis = Key<Bool>("animateWaveformAnalysis", default: true)
    static let previewWaveformAnalysis = Key<Bool>("previewWaveformAnalysis", default: true)

    enum WaveformDisplay: String, Codable {
        case bars = "bars", rounded = "hill"
        
        var title: String {
            switch(self) {
            case .bars: return "Bars"
            case .rounded: return "Rounded"
            }
        }
    }

    static let waveformDisplay = Key<WaveformDisplay>("waveformDisplay", default: .bars)
    static let trackCombinedTitleSource = Key<Bool>("trackCombinedTitleSource", default: true)
    static let trackSmallRows = Key<Bool>("trackSmallRows", default: true)

}

class ViewPreferences: NSViewController, Preferenceable {
    var toolbarItemTitle: String = "View"
    var toolbarItemIcon: NSImage = NSImage(named: NSImage.Name.colorPanelName)!
    
    @IBOutlet var initialKeyDisplay: NSPopUpButton!
    @IBOutlet var waveformDisplay: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        PopupEnum<Defaults.Keys.InitialKeyDisplay>.bind(initialKeyDisplay, toUserDefaultsKey: .initialKeyDisplay, with: [.openKey, .camelot, .english, .german], title: { $0.title })
        PopupEnum<Defaults.Keys.WaveformDisplay>.bind(waveformDisplay, toUserDefaultsKey: .waveformDisplay, with: [.bars, .rounded], title: { $0.title })
    }
    
}
