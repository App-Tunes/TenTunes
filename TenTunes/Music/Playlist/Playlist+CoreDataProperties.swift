//
//  Playlist+CoreDataProperties.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData


extension Playlist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Playlist> {
        return NSFetchRequest<Playlist>(entityName: "Playlist")
    }

    @NSManaged public var id: UUID
    @NSManaged public var creationDate: NSDate
    
    @NSManaged public var name: String
    @NSManaged public var parent: PlaylistFolder?
    
    @NSManaged public var iTunesID: String?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        if name == "" {
            name = "Unnamed Playlist"
        }

        id = UUID()
        creationDate = NSDate()
    }
}
