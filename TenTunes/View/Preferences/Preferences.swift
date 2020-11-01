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
    enum UsecaseAnswer: String, Codable {
        case casual = "casual"
        case dj = "dj"
    }
    static let initialUsecaseAnswer = Key<UsecaseAnswer>("initialUsecaseAnswer", default: .casual, suite: AppDelegate.defaults)
    
    static let libraryColumnsHidden = Key<Set<String>>("libraryColumnsHidden", default: [], suite: AppDelegate.defaults)
    static let queueColumnsHidden = Key<Set<String>>("queueColumnsHidden", default: [], suite: AppDelegate.defaults)

    static func eagerLoad() {
        // Meh, but static vars are lazily loaded......
        
        // We eager-load so the default values are
        // applied and used in-gui
        let array: [Defaults.Keys] = [
            .libraryColumnsHidden,
            .queueColumnsHidden,

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

extension Preferences.PaneIdentifier {
    static let behavior = Self("behavior")
    static let view = Self("view")
    static let files = Self("files")
}
