//
//  Track+CoreDataClass.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Track)
public class Track: NSManagedObject {
    var analysis: Analysis?
    
    var artwork: NSImage?
    var artworkPreview: NSImage?
}
