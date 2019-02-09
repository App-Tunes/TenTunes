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
    static let analyzeNewTracks = Key<Bool>("autoAnalyzeTracksOnAdd", default: true)
    
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

    static let fileLocationOnAdd = Key<FileLocationOnAdd>("fileLocationOnAdd", default: .copy)
    static let playOpenedFiles = Key<Bool>("autoPlayTracksOnOpen", default: true)
    static let editingTrackUpdatesAlbum = Key<Bool>("editingTrackUpdatesAlbum", default: true)
    static let quantizedJump = Key<Bool>("quantizedJump", default: false)
    static let keepFilterBetweenPlaylists = Key<Bool>("keepFilterBetweenPlaylists", default: false)
    static let useNormalizedVolumes = Key<Bool>("useNormalizedVolumes", default: true)

    static let trackWordSingular = Key<String>("trackWordSingular", default: "song")
    static let trackWordPlural = Key<String>("trackWordPlural", default: "songs")
}

class BehaviorPreferences: NSViewController, Preferenceable {
    var toolbarItemTitle: String = "Behavior"
    var toolbarItemIcon: NSImage = NSImage(named: .advanced)!

    @IBOutlet var fileLocationOnAdd: NSPopUpButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        PopupEnum<Defaults.Keys.FileLocationOnAdd>.bind(fileLocationOnAdd, toUserDefaultsKey: .fileLocationOnAdd, with: [.copy, .move, .link], title: { $0.title })
    }
    
}
