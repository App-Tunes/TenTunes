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
    }
    
    func addPlaylist(_ playlist: Playlist, above: Int? = nil) {
        addToChildren(playlist)
        
        if let above = above {
            children = children.rearranged(elements: [playlist], to: above)
        }
    }
    
    // TODO
    override var tracksList: [Track] {
        get { return childrenList.flatMap { $0.tracksList } }
    }
    
    override var icon: NSImage {
        return #imageLiteral(resourceName: "folder")
    }
}
