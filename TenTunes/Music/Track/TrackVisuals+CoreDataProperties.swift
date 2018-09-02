//
//  TrackVisuals+CoreDataProperties.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 02.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData


extension TrackVisuals {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackVisuals> {
        return NSFetchRequest<TrackVisuals>(entityName: "TrackVisuals")
    }

    @NSManaged public var analysis: NSData?
    @NSManaged public var artwork: NSData?
    @NSManaged public var artworkPreview: NSImage?
    @NSManaged public var track: Track!

}
