//
//  PlaylistFolder+CoreDataClass.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData

@objc(PlaylistFolder)
public class PlaylistFolder: Playlist {    
    public override func awakeFromInsert() {
        if name == "" {
            name = "Unnamed Group"
        }

        super.awakeFromInsert()
    }

    var childrenList: [Playlist] {
        get { return Array(children) as! [Playlist] }
        set { children = NSOrderedSet(array: newValue) }
    }
    
    func addPlaylist(_ playlist: Playlist, above: Int? = nil) {
        addToChildren(playlist)
        
        if let above = above {
            children = children.rearranged(elements: [playlist], to: above)
        }
    }
    
    var automatesChildren: Bool {
        return false
    }
    
    override func _freshTracksList(rguard: RecursionGuard<Playlist>) -> [Track] {
        return (childrenList.flatMap { $0.guardedTracksList(rguard: rguard) }).uniqueElements
    }
    
    override var icon: NSImage {
        return #imageLiteral(resourceName: "folder")
    }
}
