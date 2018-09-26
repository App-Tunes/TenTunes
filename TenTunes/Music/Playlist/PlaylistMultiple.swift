//
//  PlaylistMultiple.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class PlaylistMultiple : PlaylistProtocol {
    let playlists: [PlaylistProtocol]
    
    required init(playlists: [PlaylistProtocol]) {
        self.playlists = playlists
    }
    
    var name: String {
        return playlists.map { $0.name }.joined(separator: ", ")
    }
    
    var tracksList: [Track] {
        return playlists.flatMap { $0.tracksList }.uniqueElements
    }
    
    func convert(to: NSManagedObjectContext) -> Self? {
        let converted = playlists.compactMap { $0.convert(to: to) }
        return converted.count == playlists.count ? type(of: self).init(playlists: converted) : nil
    }
}
