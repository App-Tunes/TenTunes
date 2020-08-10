//
//  BehaviorPreferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Preferences
import Defaults

extension Defaults.Keys {
    static let analyzeNewTracks = Key<Bool>("autoAnalyzeTracksOnAdd", default: true, suite: AppDelegate.defaults)
    
    enum FileLocationOnAdd: String, Codable {
        case link = "link", copy = "copy", move = "move"
        
        var title: String {
            switch(self) {
            case .link: return "Link to the file"
            case .copy: return "Copy to Media Directory"
            case .move: return "Move to Media Directory"
            }
        }
    }

    static let fileLocationOnAdd = Key<FileLocationOnAdd>("fileLocationOnAdd", default: .copy, suite: AppDelegate.defaults)
    static let playOpenedFiles = Key<Bool>("autoPlayTracksOnOpen", default: true, suite: AppDelegate.defaults)
    static let editingTrackUpdatesAlbum = Key<Bool>("updatingTrackUpdatesAlbum", default: true, suite: AppDelegate.defaults)
    static let quantizedJump = Key<Bool>("quantizedJump", default: false, suite: AppDelegate.defaults)
    static let keepFilterBetweenPlaylists = Key<Bool>("keepFilterBetweenPlaylists", default: false, suite: AppDelegate.defaults)
    static let useNormalizedVolumes = Key<Bool>("useNormalizedVolumes", default: true, suite: AppDelegate.defaults)

    static let trackWordSingular = Key<String>("trackWordSingular", default: "song", suite: AppDelegate.defaults)
    static let trackWordPlural = Key<String>("trackWordPlural", default: "songs", suite: AppDelegate.defaults)
}

class BehaviorPreferences: NSViewController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.behavior
    var preferencePaneTitle = "Behavior"
    var toolbarItemIcon = NSImage(named: NSImage.Name.advancedName)!

    override var nibName: NSNib.Name? {
        return "BehaviorPreferences"
    }

    @IBOutlet var fileLocationOnAdd: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        PopupEnum<Defaults.Keys.FileLocationOnAdd>.bind(fileLocationOnAdd, toUserDefaultsKey: .fileLocationOnAdd, with: [.copy, .move, .link], title: { $0.title })
    }
    
}
