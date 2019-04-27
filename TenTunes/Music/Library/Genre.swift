//
//  Genre.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class Genre {
    let name: String
    var _tracks: [Track]?
    
    init(name: String) {
        self.name = name
    }
    
    var tracks: [Track] {
        if _tracks == nil {
            _tracks = Library.shared.allTracks().filter {
                $0.genre == name
            }
        }
        
        return _tracks!
    }
}

extension Genre : CustomStringConvertible {
    var description: String {
        return name
    }
}

extension Genre : Comparable {
    static func < (lhs: Genre, rhs: Genre) -> Bool {
        return lhs.name < rhs.name
    }
}

extension Genre : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name.lowercased())
    }
    
    static func == (lhs: Genre, rhs: Genre) -> Bool {
        return lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame
    }
}
