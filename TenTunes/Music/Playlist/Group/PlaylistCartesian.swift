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
        
        if cross.count != childrenList.count || cross != Set(childrenRules) {
            for error in childrenList.retain({
                (CartesianRules.Combination(from: $0) ?=> cross.contains) ?? false
            }) {
                context.delete(error) // Harsh measues but with GUI validation this should not happen anyway
            }
            for combination in cross where !childrenRules.contains(combination) {
                let playlist = PlaylistSmart(context: context)
                playlist.rules = combination.rules
                playlist.name = combination.name
                addToChildren(playlist)
                // TODO Fix the program trying to autoname these
            }
        }
    }
    
    func crossProduct(in context: NSManagedObjectContext) -> Set<CartesianRules.Combination> {
        return rules.crossProduct(in: context)
    }
}
