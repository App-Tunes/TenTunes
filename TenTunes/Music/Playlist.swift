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
    var children: [Playlist]? = nil
    
    init(folder: Bool) {
        if folder {
            children = []
        }
    }
    
    func track(at: Int) -> Track? {
        return tracks[at]
    }
    
    var size: Int {
        return tracks.count
    }
    
    var isFolder: Bool {
        return children != nil
    }
        
    func add(child: Playlist) {
        if !isFolder {
            fatalError("Not a folder!") 
        }
        children!.append(child)
        tracks.append(contentsOf: child.tracks)
    }
}

extension Playlist : Equatable {
    static func ==(lhs: Playlist, rhs: Playlist) -> Bool {
        return lhs.id == rhs.id
    }
}
