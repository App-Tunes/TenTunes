//
//  PlaylistFolder+CoreDataProperties.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData


extension PlaylistFolder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaylistFolder> {
        return NSFetchRequest<PlaylistFolder>(entityName: "PlaylistFolder")
    }

    @NSManaged public var children: NSOrderedSet

}

// MARK: Generated accessors for children
extension PlaylistFolder {

    @objc(insertObject:inChildrenAtIndex:)
    @NSManaged public func insertIntoChildren(_ value: Playlist, at idx: Int)

    @objc(removeObjectFromChildrenAtIndex:)
    @NSManaged public func removeFromChildren(at idx: Int)

    @objc(insertChildren:atIndexes:)
    @NSManaged public func insertIntoChildren(_ values: [Playlist], at indexes: NSIndexSet)

    @objc(removeChildrenAtIndexes:)
    @NSManaged public func removeFromChildren(at indexes: NSIndexSet)

    @objc(replaceObjectInChildrenAtIndex:withObject:)
    @NSManaged public func replaceChildren(at idx: Int, with value: Playlist)

    @objc(replaceChildrenAtIndexes:withChildren:)
    @NSManaged public func replaceChildren(at indexes: NSIndexSet, with values: [Playlist])

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: Playlist)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: Playlist)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSOrderedSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSOrderedSet)

}
