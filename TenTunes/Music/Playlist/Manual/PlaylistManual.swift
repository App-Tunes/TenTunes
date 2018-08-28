//
//  PlaylistManual+CoreDataClass.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData

@objc(PlaylistManual)
public class PlaylistManual: Playlist {
    override func _freshTracksList(rguard: RecursionGuard<Playlist>) -> [Track] {
        return Array(tracks) as! [Track] 
    }
}

extension PlaylistManual : ModifiablePlaylist {
    func supports(action: ModifyingAction) -> Bool {
        return true
    }
    
    func addTracks(_ tracks: [Track], above: Int?) {
        // Add the tracks we're missing
        // TODO Allow duplicates after asking
        // Is set so by default not allowed
        addToTracks(NSOrderedSet(array: tracks))
        
        if let above = above {
            self.tracks = self.tracks.rearranged(elements: tracks, to: above)
        }
    }
    
    func removeTracks(_ tracks: [Track]) {
        removeFromTracks(NSOrderedSet(array: tracks))
    }
}
