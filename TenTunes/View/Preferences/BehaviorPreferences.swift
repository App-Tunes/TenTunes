//
//  BehaviorPreferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Preferences

extension UserDefaults {
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
        
    var forceSimpleFilePaths: Bool {
        return bool(forKey: "forceSimpleFilePaths")
    }
    
    var useNormalizedVolumes: Bool {
        return bool(forKey: "useNormalizedVolumes")
    }
    
    @objc dynamic var trackWordSingular: String {
        return string(forKey: "trackWordSingular") ?? "song"
    }
    
    @objc dynamic var trackWordPlural: String {
        return string(forKey: "trackWordPlural") ?? "songs"
    }
}

class BehaviorPreferences: NSViewController, Preferenceable {
    var toolbarItemTitle: String = "Behavior"
    var toolbarItemIcon: NSImage = NSImage(named: .advanced)!

    @IBOutlet var fileLocationOnAdd: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        PopupEnum<UserDefaults.FileLocationOnAdd>.bind(fileLocationOnAdd, toUserDefaultsKey: UserDefaults.FileLocationOnAdd.key, with: [.copy, .move, .link], by: { $0.rawValue }, title: { $0.title })
    }
    
}
