//
//  Track+CoreDataProperties.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData


extension Track {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Track> {
        return NSFetchRequest<Track>(entityName: "Track")
    }

    @NSManaged public var id: UUID
    @NSManaged public var creationDate: NSDate
    
    @NSManaged public var album: String?
    @NSManaged public var analysisData: NSData?
    @NSManaged public var artworkData: NSData?
    @NSManaged public var artworkPreviewData: NSData?
    @NSManaged public var author: String?
    @NSManaged public var bpmR: Double
    @NSManaged public var durationR: Int64
    @NSManaged public var genre: String?
    @NSManaged public var iTunesID: String?
    @NSManaged public var keyString: String?
    @NSManaged public var path: String?
    @NSManaged public var title: String?
    @NSManaged public var containingPlaylists: NSSet

    public override func awakeFromInsert() {
        id = UUID()
        creationDate = NSDate()
    }
}

// MARK: Generated accessors for containingPlaylists
extension Track {

    @objc(addContainingPlaylistsObject:)
    @NSManaged public func addToContainingPlaylists(_ value: PlaylistManual)

    @objc(removeContainingPlaylistsObject:)
    @NSManaged public func removeFromContainingPlaylists(_ value: PlaylistManual)

    @objc(addContainingPlaylists:)
    @NSManaged public func addToContainingPlaylists(_ values: NSSet)

    @objc(removeContainingPlaylists:)
    @NSManaged public func removeFromContainingPlaylists(_ values: NSSet)

}
