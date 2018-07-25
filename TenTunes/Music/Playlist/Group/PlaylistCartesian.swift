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
        let cross = crossProduct(in: context)
        let childrenRules = childrenList.compactMap(CartesianRules.Combination.init)
        
        if cross.count != childrenList.count || cross != childrenRules {
            for (required, existing) in longZip(cross, childrenList) {
                guard required?.rules.labels != (existing as? PlaylistSmart)?.rules?.labels else {
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
                }
            }
        }
    }
    
    func crossProduct(in context: NSManagedObjectContext) -> [CartesianRules.Combination] {
        return rules.crossProduct(in: context)
    }
}
