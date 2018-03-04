//
//  Playlist+CoreDataClass.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Playlist)
public class Playlist: NSManagedObject, PlaylistProtocol {
    
    static let pasteboardType = NSPasteboard.PasteboardType(rawValue: "tentunes.playlist")

    var tracksList: [Track] {
        return []
    }
    
    func track(at: Int) -> Track? {
        return tracksList[at]
    }
    
    var size: Int {
        return tracksList.count
    }
    
    var icon: NSImage {
        return #imageLiteral(resourceName: "playlist")
    }
}
