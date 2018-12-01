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
    
    @objc dynamic var trackColumnsHidden: [String: Bool] {
        return dictionary(forKey: "trackColumnsHidden") as! [String: Bool]
    }
    
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
    }

    var initialKeyDisplay: InitialKeyDisplay {
        return (string(forKey: InitialKeyDisplay.key) ?=> InitialKeyDisplay.init) ?? .camelot
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
    
    enum AnalyzeNewTracks {
        static let key: String = "autoAnalyzeTracksOnAdd"
        case analyze, dont
    }
    
    var analyzeNewTracks: AnalyzeNewTracks {
        return bool(forKey: AnalyzeNewTracks.key) ? .analyze : .dont
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
    }
    
    var fileLocationOnAdd: FileLocationOnAdd {
        return (string(forKey: FileLocationOnAdd.key) ?=> FileLocationOnAdd.init) ?? .copy
    }
    
    enum PlayOpenedFiles {
        static let key: String = "autoPlayTracksOnOpen"
        case play, dont
    }
    
    var playOpenedFiles: PlayOpenedFiles {
        return bool(forKey: PlayOpenedFiles.key) ? .play : .dont
    }
    
    enum EditingTrackUpdatesAlbum {
        static let key: String = "updatingTrackUpdatesAlbum"
        case update, dont
    }
    
    var editingTrackUpdatesAlbum: EditingTrackUpdatesAlbum {
        return bool(forKey: EditingTrackUpdatesAlbum.key) ? .update : .dont
    }
    
    var quantizedJump: Bool {
        return bool(forKey: "quantizedJump")
    }
    
    var keepFilterBetweenPlaylists: Bool {
        return bool(forKey: "keepFilterBetweenPlaylists")
    }
    
    var trackCombinedTitleSource: Bool {
        return bool(forKey: "trackCombinedTitleSource")
    }

    var trackSmallRows: Bool {
        return bool(forKey: "trackSmallRows")
    }
}

class PreferencesWindowController: NSWindowController {

    @IBOutlet var initialKeyDisplay: NSPopUpButton!
    
    @IBOutlet var waveformDisplay: NSPopUpButton!

    @IBOutlet var fileLocationOnAdd: NSPopUpButton!

    override func windowDidLoad() {
        super.windowDidLoad()

        PopupEnum<UserDefaults.InitialKeyDisplay>.bind(initialKeyDisplay, toUserDefaultsKey: UserDefaults.InitialKeyDisplay.key, with: [.camelot, .english, .german], by: { $0.rawValue }, title: { $0.title })
        PopupEnum<UserDefaults.WaveformDisplay>.bind(waveformDisplay, toUserDefaultsKey: UserDefaults.WaveformDisplay.key, with: [.bars, .rounded], by: { $0.rawValue }, title: { $0.title })
        PopupEnum<UserDefaults.FileLocationOnAdd>.bind(fileLocationOnAdd, toUserDefaultsKey: UserDefaults.FileLocationOnAdd.key, with: [.copy, .move, .link], by: { $0.rawValue }, title: { $0.title })
    }
}
