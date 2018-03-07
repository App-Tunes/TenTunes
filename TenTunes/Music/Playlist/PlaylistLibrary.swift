//
//  PlaylistLibrary.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class PlaylistLibrary: PlaylistProtocol {    
    var childrenList: [Playlist]? {
        return nil
    }
    
    var tracksList: [Track] {
        let tracks: [Track] = try! Library.shared.viewMox.fetch(Track.fetchRequest())
        return tracks.sorted { $0.objectID.uriRepresentation().absoluteString < $1.objectID.uriRepresentation().absoluteString }
    }
}
