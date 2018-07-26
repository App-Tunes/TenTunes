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
            let all = Library.shared.allTracks.convert(to: managedObjectContext!)!.tracksList
            return all.filter(filter(in: managedObjectContext!))
        }
    }
        
    func filter(in context: NSManagedObjectContext) -> (Track) -> Bool {
        return rrules.filter(in: context)
    }
    
    override var icon: NSImage {
        return #imageLiteral(resourceName: "playlist-smart")
    }
}
