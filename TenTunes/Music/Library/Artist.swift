//
//  Artist.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.08.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Artist {
    let name: String
    
    init(name: String) {
        self.name = name
    }

    //    class func authors(of track: Track) -> [Artist] {
//        return [Artist(name: track.rAuthor)]
//    }
}

extension Artist : CustomStringConvertible {
    class func describe(_ artist: Artist?) -> String {
        return artist?.description ?? "Unknown Artist"
    }
    
    var description: String {
        return name
    }
}

extension Artist : Hashable {
    var hashValue: Int {
        return name.lowercased().hashValue
    }
    
    static func == (lhs: Artist, rhs: Artist) -> Bool {
        return lhs.name.lowercased() == rhs.name.lowercased()
    }
}
