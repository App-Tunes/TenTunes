//
//  PlaylistEmpty.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.04.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

class PlaylistEmpty : PlaylistProtocol {
    var name: String {
        return ""
    }
    
    var icon: NSImage {
        return NSImage(named: .init("playlist"))!
    }
    
    var persistentID: UUID {
        // All empty playlists are the same
        return UUID(uuidString: "41d32a56-e774-4205-88bd-71020e2674c0")!
    }
    
    var tracksList: [Track] {
        return []
    }
    
    func convert(to: NSManagedObjectContext) -> Self? {
        return self
    }
}
