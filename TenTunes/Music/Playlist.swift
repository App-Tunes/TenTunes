//
//  Playlist.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Playlist {
    var id: String = ""
    var name: String = "Unnamed Playlist"
    
    var tracks: [Track] = []
    var children: [Playlist] = []
    
    func track(at: Int) -> Track? {
        return tracks[at]
    }
    
    var size: Int {
        return tracks.count
    }
}
