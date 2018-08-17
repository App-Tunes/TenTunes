//
//  Album.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Album {
    let title: String
    let author: String
    
    convenience init(of track: Track) {
        self.init(title: track.rAlbum, by: track.albumArtist ?? track.rAuthor)
    }
    
    init(title: String, by author: String) {
        self.title = title
        self.author = author
    }
}

extension Album : Hashable {
    var hashValue: Int {
        return title.hashValue ^ author.hashValue
    }
    
    static func == (lhs: Album, rhs: Album) -> Bool {
        return lhs.title.lowercased() == rhs.title.lowercased() &&
            lhs.author.lowercased() == rhs.author.lowercased()
    }
}
