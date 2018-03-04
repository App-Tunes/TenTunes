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
    convenience init() {
        self.init(mox: Library.shared.persistentContainer.viewContext)
    }
    
    convenience init(mox: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: "PlaylistFolder", in:mox)!, insertInto: mox)
        
        name = "Unnamed Group"
    }
    
    var childrenList: [Playlist] {
        get { return Array(children) as! [Playlist] }
    }
    
    // TODO
    override var tracksList: [Track] {
        get { return childrenList.flatMap { $0.tracksList } }
    }
    
    override var icon: NSImage {
        return #imageLiteral(resourceName: "folder")
    }
}
