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
        let request: NSFetchRequest = Track.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return try! Library.shared.viewMox.fetch(request)
    }
}
