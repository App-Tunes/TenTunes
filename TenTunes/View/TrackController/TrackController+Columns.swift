//
//  TrackController+Columns.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 01.11.20.
//  Copyright © 2020 ivorius. All rights reserved.
//

import Foundation
import Defaults

extension TrackController {
    enum CellIdentifiers {
        static let artwork = NSUserInterfaceItemIdentifier(rawValue: "artworkCell")
        static let staticArtwork = NSUserInterfaceItemIdentifier(rawValue: "staticArtworkCell")
        static let waveform = NSUserInterfaceItemIdentifier(rawValue: "waveformCell")
        static let title = NSUserInterfaceItemIdentifier(rawValue: "titleCell")
        static let combinedTitle = NSUserInterfaceItemIdentifier(rawValue: "combinedTitleCell")
        static let author = NSUserInterfaceItemIdentifier(rawValue: "authorCell")
        static let album = NSUserInterfaceItemIdentifier(rawValue: "albumCell")
        static let genre = NSUserInterfaceItemIdentifier(rawValue: "genreCell")
        static let bpm = NSUserInterfaceItemIdentifier(rawValue: "bpmCell")
        static let key = NSUserInterfaceItemIdentifier(rawValue: "keyCell")
        static let duration = NSUserInterfaceItemIdentifier(rawValue: "durationCell")
        static let dateAdded = NSUserInterfaceItemIdentifier(rawValue: "dateAddedCell")
        static let year = NSUserInterfaceItemIdentifier(rawValue: "yearCell")
        static let playCount = NSUserInterfaceItemIdentifier(rawValue: "playCountCell")
    }
    
    enum ColumnIdentifiers {
        static let artwork = NSUserInterfaceItemIdentifier(rawValue: "artworkColumn")
        static let waveform = NSUserInterfaceItemIdentifier(rawValue: "waveformColumn")
        static let title = NSUserInterfaceItemIdentifier(rawValue: "titleColumn")
        static let author = NSUserInterfaceItemIdentifier(rawValue: "authorColumn")
        static let album = NSUserInterfaceItemIdentifier(rawValue: "albumColumn")
        static let genre = NSUserInterfaceItemIdentifier(rawValue: "genreColumn")
        static let bpm = NSUserInterfaceItemIdentifier(rawValue: "bpmColumn")
        static let key = NSUserInterfaceItemIdentifier(rawValue: "keyColumn")
        static let duration = NSUserInterfaceItemIdentifier(rawValue: "durationColumn")
        static let dateAdded = NSUserInterfaceItemIdentifier(rawValue: "dateAddedColumn")
        static let year = NSUserInterfaceItemIdentifier(rawValue: "yearColumn")
        static let playCount = NSUserInterfaceItemIdentifier(rawValue: "playCountColumn")
    }
    
    static let tracksListColumns: [Defaults.Keys.UsecaseAnswer: [NSUserInterfaceItemIdentifier]] = [
        .casual: [
            ColumnIdentifiers.artwork,
            ColumnIdentifiers.waveform,
            ColumnIdentifiers.title,
            ColumnIdentifiers.genre,
            ColumnIdentifiers.duration,
        ],
        .dj: [
            ColumnIdentifiers.artwork,
            ColumnIdentifiers.waveform,
            ColumnIdentifiers.title,
            ColumnIdentifiers.genre,
            ColumnIdentifiers.key,
            ColumnIdentifiers.bpm,
            ColumnIdentifiers.duration,
        ],
    ]
    
    static let queueColumns: [Defaults.Keys.UsecaseAnswer: [NSUserInterfaceItemIdentifier]] = [
        .casual: [
            ColumnIdentifiers.artwork,
            ColumnIdentifiers.title,
            ColumnIdentifiers.duration,
        ],
        .dj: [
            ColumnIdentifiers.artwork,
            ColumnIdentifiers.title,
            ColumnIdentifiers.key,
            ColumnIdentifiers.bpm,
            ColumnIdentifiers.duration,
        ],
    ]

    func readColumnDefaults() {
        guard let columns = (mode == .tracksList ? Self.tracksListColumns : Self.queueColumns)[Defaults[.initialUsecaseAnswer]] else {
            print("Failed to read columns to hide")
            return
        }
        
        let key: Defaults.Key = mode == .tracksList ? .libraryColumnsHidden : .queueColumnsHidden
        
        let unhideable = Defaults[key] + Set(columns.map { $0.rawValue })
        
        for column in _tableView.tableColumns {
            if !unhideable.contains(column.identifier.rawValue) {
                column.isHidden = true
                Defaults[key].insert(column.identifier.rawValue)
            }
        }
    }
}
