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
        
    var filter: (Track) -> Bool {
        return rules.filter
    }
}
