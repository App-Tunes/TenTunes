//
//  PlaylistCartesian.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 20.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc(PlaylistCartesian)
class PlaylistCartesian: PlaylistFolder {    
    func checkSanity(in context: NSManagedObjectContext) {
        let allTracks = Library.shared.allTracks.convert(to: context)!.tracksList
        
        let cross = crossProduct(in: context)
            .filter { allTracks.anyMatch($0.rules.filter(in: context)) }
        let childrenRules = childrenList.compactMap(CartesianRules.Combination.init)
        
        if cross.count != childrenList.count || cross != childrenRules {
            for (index, (required, existing)) in longZip(cross, childrenList).enumerated() {
                guard required?.rules.labels != (existing as? PlaylistSmart)?.rules?.labels || required?.name != existing?.name else {
                    continue
                }
                
                if let existing = existing {
                    context.delete(existing)
                }
                
                if let required = required {
                    let playlist = PlaylistSmart(context: context)
                    playlist.rules = required.rules
                    playlist.name = required.name
                    // TODO Fix the program trying to autoname these
                    addToChildren(playlist)
                    
                    if existing != nil { // Deleted one as well, means we're in the middle
                        children = children.rearranged(elements: [playlist], to: index)
                    }
                }
            }
        }
    }
    
    override var automatesChildren: Bool {
        return true
    }
    
    override func _freshTracksList(rguard: RecursionGuard<Playlist>) -> [Track] {
        guard rguard.push(self) else {
            return [] // TODO Find a better way
        }
        
        let all = Library.shared.allTracks.convert(to: managedObjectContext!)!.tracksList
        let tracks = all.filter(combinedFilter(in: managedObjectContext!))
        
        rguard.pop(self)
        
        return tracks
    }
    
    func combinedFilter(in context: NSManagedObjectContext) -> (Track) -> Bool {
        return rules.combinedFilter(in: context)
    }
    
    func crossProduct(in context: NSManagedObjectContext) -> [CartesianRules.Combination] {
        return rules.crossProduct(in: context)
    }
    
    override var icon: NSImage {
        return #imageLiteral(resourceName: "playlist-cartesian")
    }
}
