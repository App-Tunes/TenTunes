//
//  Preferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Defaults

import Preferences

extension Defaults.Keys {
    static let trackColumnsHidden = Key<[String: Bool]>("trackColumnsHidden", default: [
        "albumColumn" : true,
        "authorColumn" : true,
        "yearColumn" : true,
        "dateAddedColumn" : true,
        "keyColumn" : true,
        "bpmColumn" : true,
        "playCountColumn" : true
    ])
    
    enum UsecaseAnswer: String, Codable {
        case casual = "casual"
        case dj = "dj"
    }
    static let initialUsecaseAnswer = Key<UsecaseAnswer>("initialUsecaseAnswer", default: .casual)

    static func eagerLoad() {
        // Meh, but static vars are lazily loaded......
        
        // We eager-load so the default values are
        // applied and used in-gui
        let array: [Defaults.Keys] = [
            .trackColumnsHidden,
            
            .analyzeNewTracks,
            .fileLocationOnAdd,
            .playOpenedFiles,
            .editingTrackUpdatesAlbum,
            .quantizedJump,
            .keepFilterBetweenPlaylists,
            .useNormalizedVolumes,
            .trackWordSingular,
            .trackWordPlural,
            
            .titleBarStylization,
            .initialKeyDisplay,
            .waveformAnimation,
            .waveformDisplay,
            .trackCombinedTitleSource,
            .trackSmallRows,
            
            .forceSimpleFilePaths,
            .skipExportITunes,
            .skipExportM3U,
            .skipExportAlias,
        ]
        
        _ = array
    }
}

extension PreferencePane.Identifier {
    static let behavior = Identifier("behavior")
    static let view = Identifier("view")
    static let files = Identifier("files")
}
