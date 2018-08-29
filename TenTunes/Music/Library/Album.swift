//
//  Album.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Album {
    static let unknown = "Unknown Album"

    let title: String
    let author: Artist?
    
    init(title: String, by author: Artist?) {
        self.title = title
        self.author = author
    }
}

extension Album : Hashable {
    var hashValue: Int {
        return title.lowercased().hashValue ^ (author?.hashValue ?? 0)
    }
    
    static func == (lhs: Album, rhs: Album) -> Bool {
        return lhs.title.lowercased() == rhs.title.lowercased() &&
            lhs.author == rhs.author
    }
}
