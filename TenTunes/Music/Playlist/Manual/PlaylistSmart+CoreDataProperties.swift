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
    
    @NSManaged public var rules: PlaylistRules!
    
    func markRulesDirty() {
        let rules = self.rules
        self.rules = rules // Eww, but need this to mark it to Core Data
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        if rules == nil {
            rules = PlaylistRules()
        }
    }
}
