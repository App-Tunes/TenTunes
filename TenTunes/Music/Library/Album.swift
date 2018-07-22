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
        return lhs.title == rhs.title && lhs.author == rhs.author
    }
}
