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
    struct Combination : Hashable {
        let name: String
        let rules: PlaylistRules
        
        init(name: String, rules: PlaylistRules) {
            self.name = name
            self.rules = rules
        }
        
        init?(from: Playlist) {
            guard let rules = (from as? PlaylistSmart)?.rules else {
                return nil
            }
            
            self.init(name: from.name, rules: rules)
        }
    }
    
    func checkSanity(in context: NSManagedObjectContext? = nil) {
        let context = context ?? Library.shared.viewContext
        
        let cross = crossProduct()
        let childrenRules = childrenList.compactMap(Combination.init)
        
        if cross.count != childrenList.count || cross != Set(childrenRules) {
            for error in childrenList.retain({
                (Combination(from: $0) ?=> cross.contains) ?? false
            }) {
                removeFromChildren(error)
            }
            for combination in cross where !childrenRules.contains(combination) {
                let playlist = PlaylistSmart(context: context)
                playlist.rules = combination.rules
                playlist.name = combination.name
                addToChildren(playlist)
            }
        }
    }
    
    func crossProduct() -> Set<Combination> {
        let ltmp = Library.shared.tagPlaylist.childrenList[safe: 0] as? PlaylistFolder
        let rtmp = Library.shared.tagPlaylist.childrenList[safe: 1] as? PlaylistFolder
        
        guard let left = ltmp?.childrenList, let right = rtmp?.childrenList else {
            return Set((self.left ?? self.right)?.childrenList.map { source in
                let rules = PlaylistRules(labels: [PlaylistLabel(playlist: source, isTag: false)])
                return Combination(name: source.name, rules: rules)
            } ?? [])
        }
        
        return Set(left.crossProduct(right).map { (left, right) in
            let name = "\(left.name) | \(right.name)"
            let rules = PlaylistRules(labels: [
                PlaylistLabel(playlist: left, isTag: false),
                PlaylistLabel(playlist: right, isTag: false)
                ])
            return Combination(name: name, rules: rules)
        })
    }
}
