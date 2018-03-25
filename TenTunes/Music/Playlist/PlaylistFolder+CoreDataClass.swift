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
    convenience init() { // TODO Remove?
        self.init(mox: Library.shared.viewContext)
    }
    
    convenience init(mox: NSManagedObjectContext) { // TODO Remove?
        self.init(entity: NSEntityDescription.entity(forEntityName: "PlaylistFolder", in:mox)!, insertInto: mox)
        
        name = "Unnamed Group"
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
