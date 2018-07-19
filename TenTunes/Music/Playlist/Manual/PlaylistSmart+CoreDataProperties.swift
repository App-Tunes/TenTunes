//
//  PlaylistSmart+CoreDataProperties.swift
//  
//
//  Created by Lukas Tenbrink on 19.07.18.
//
//

import Foundation
import CoreData

extension PlaylistSmart {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaylistSmart> {
        return NSFetchRequest<PlaylistSmart>(entityName: "PlaylistSmart")
    }

    var labels: [Label] {
        get { return labelArray as! [Label] }
        set { labelArray = newValue as NSArray }
    }
    
    @NSManaged public var labelArray: NSArray
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        if labelArray.count == 0 {
            labelArray = NSArray()
        }
    }
}
