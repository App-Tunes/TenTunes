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
    override func _freshTracksList(rguard: RecursionGuard<Playlist>) -> [Track] {
        guard rguard.push(self) else {
            return []
        }
        
        let all = Library.shared.allTracks.convert(to: managedObjectContext!)!.tracksList
        let tracks = all.filter(filter(in: managedObjectContext!, rguard: rguard))
        
        rguard.pop(self)
        
        return tracks
    }
        
    func filter(in context: NSManagedObjectContext, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
        return rrules.filter(in: context, rguard: rguard)
    }
    
    override var icon: NSImage {
        return #imageLiteral(resourceName: "playlist-smart")
    }
}
