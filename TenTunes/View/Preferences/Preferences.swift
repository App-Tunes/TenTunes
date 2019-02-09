//
//  Preferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Defaults

extension Defaults.Keys {
    static let trackColumnsHidden = Key<[String: Bool]>("trackColumnsHidden", default: [
        "albumColumn" : true,
        "authorColumn" : true,
        "yearColumn" : true,
        "dateAddedColumn" : true,
        "keyColumn" : true,
        "bpmColumn" : true
        ])
    
    static func eagerLoad() {
        // Meh, but static vars are lazily loaded......
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
            .animateWaveformTransitions,
            .animateWaveformAnalysis,
            .previewWaveformAnalysis,
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
