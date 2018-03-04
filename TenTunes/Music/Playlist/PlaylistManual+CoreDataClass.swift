//
//  PlaylistManual+CoreDataClass.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData

@objc(PlaylistManual)
public class PlaylistManual: Playlist {
    convenience init() {
        self.init(mox: Library.shared.persistentContainer.viewContext)
    }
    
    convenience init(mox: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: "PlaylistManual", in:mox)!, insertInto: mox)
        
        name = "Unnamed Playlist"
    }
    
    override var tracksList: [Track] {
        get { return Array(tracks) as! [Track] }
    }
}
