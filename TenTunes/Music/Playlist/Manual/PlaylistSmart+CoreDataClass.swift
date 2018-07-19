//
//  PlaylistSmart+CoreDataClass.swift
//  
//
//  Created by Lukas Tenbrink on 19.07.18.
//
//

import Foundation
import CoreData

@objc(PlaylistSmart)
public class PlaylistSmart: Playlist {
    override var tracksList: [Track] {
        get {
            return Library.shared.allTracks.tracksList.filter(filter)
        }
    }
    
    static func filter(of labels: [Label]) -> ((Track) -> Bool) {
        let filters = labels.map { $0.filter() }
        return { track in
            return filters.allMatch { $0(track) }
        }
    }
    
    var filter: (Track) -> Bool {
        return PlaylistSmart.filter(of: labels)
    }
    
    var labels: [Label] {
        return [
        ]
    }
}
