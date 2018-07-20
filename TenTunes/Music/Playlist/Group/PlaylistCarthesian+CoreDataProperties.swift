//
//  PlaylistCartesian+CoreDataProperties.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 20.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension PlaylistCartesian {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaylistCartesian> {
        return NSFetchRequest<PlaylistCartesian>(entityName: "PlaylistCartesian")
    }
    
    @NSManaged public var left: PlaylistFolder?
    @NSManaged public var right: PlaylistFolder?

}
