//
//  Artist.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.08.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Artist {
    static let splitRegex = try! NSRegularExpression(pattern: "((\\s*,)|(\\s+(f(ea)?t(uring)?\\.?)))\\s+", options: [])
    static let unknown = "Unknown Artist"
    
    let name: String
    
    init(name: String) {
        self.name = name
    }

    class func all(in string: String) -> [Artist] {
        return splitRegex.split(string: string).map(Artist.init)
    }
}

extension Artist : CustomStringConvertible {
    class func describe(_ artist: Artist?) -> String {
        return artist?.description ?? Artist.unknown
    }
    
    class func describe(_ artists: [Artist]) -> String {
        return artists.isEmpty ? Artist.unknown : artists.map { $0.description }.joined(separator: ", ")
    }
    
    var description: String {
        return name
    }
}

extension Artist : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name.lowercased())
    }
    
    static func == (lhs: Artist, rhs: Artist) -> Bool {
        return lhs.name.lowercased() == rhs.name.lowercased()
    }
}
