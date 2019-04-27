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
    
    enum InitialKeyDisplay: Codable, Equatable {
        case custom(type: InitialKeyWrite)
        case file, idealFile

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let custom = try? InitialKeyWrite.init(from: decoder) {
                self = .custom(type: custom)
                return
            }
            
            switch try container.decode(String.self) {
            case "file": self = .file
            case "idealFile": self = .idealFile
            default: throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized Value")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(write)
        }
        
        var write: String {
            switch(self) {
            case .custom(let type): return type.rawValue
            case .file: return "file"
            case .idealFile: return "idealFile"
            }
        }
        
        var title: String {
            switch(self) {
            case .custom(let type): return type.title
            case .file: return "From File"
            case .idealFile: return "Default"
            }
        }
        
        static func ==(lhs: InitialKeyDisplay, rhs: InitialKeyDisplay) -> Bool {
            return lhs.write == rhs.write
        }
    }

    static let initialKeyDisplay = Key<InitialKeyDisplay>("initialKeyDisplay", default: .idealFile)
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

    static let waveformColorRotation = Key<Double>("waveformColorRotation", default: 0.0)
}

class ViewPreferences: NSViewController, Preferenceable {
    var toolbarItemTitle: String = "View"
    var toolbarItemIcon: NSImage = NSImage(named: NSImage.Name.colorPanelName)!
    
    @IBOutlet var initialKeyDisplay: NSPopUpButton!
    @IBOutlet var waveformDisplay: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let customDisplays = Defaults.Keys.InitialKeyWrite.values.map(Defaults.Keys.InitialKeyDisplay.custom)
        PopupEnum<Defaults.Keys.InitialKeyDisplay>.bind(initialKeyDisplay, toUserDefaultsKey: .initialKeyDisplay, with: [.idealFile, .file] + customDisplays, title: { $0.title })
        PopupEnum<Defaults.Keys.WaveformDisplay>.bind(waveformDisplay, toUserDefaultsKey: .waveformDisplay, with: [.bars, .rounded], title: { $0.title })
    }
    
}
