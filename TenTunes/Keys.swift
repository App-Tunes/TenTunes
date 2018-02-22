//
//  Keys.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 21.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

enum Note {
    case A, Bb, B, C, Db, D, Eb, E, F, Gb, G, Ab
    
    static var camelotWheel: [Note] = [.C, .G, .D, .A, .E, .B, .Gb, .Db, .Ab, .Eb, .Bb, .F]
    static var order: [Note] = [.A, .Bb, .B, .C, .Db, .D, .Eb, .E, .F, .Gb, .G, .Ab]

    static func parse(string: String, isMinor: Bool) -> Note? {
        for note in Note.order {
            if note.description == string {
                return note
            }
        }
        
        if let i = Int(string) {
            if i >= 1 && i <= 12 {
                return camelotWheel[(i - 1 + (isMinor ? 3 : 0)) % camelotWheel.count]
            }
        }
        
        return nil
    }
    
    var camelot: Int {
        return Note.camelotWheel.index(of: self)!
    }
    
    var description: String {
        switch self {
        case .A:
            return "A"
        case .Bb:
            return "Bb"
        case .B:
            return "B"
        case .C:
            return "C"
        case .Db:
            return "Db"
        case .D:
            return "D"
        case .Eb:
            return "Eb"
        case .E:
            return "E"
        case .F:
            return "F"
        case .Gb:
            return "Gb"
        case .G:
            return "G"
        case .Ab:
            return "Ab"
        default:
            return ""
        }
    }
}

class Key {
    var note: Note
    var isMinor: Bool

    static func parse(string: String) -> Key? {
        let isMinor = string.last == "m"
        let noteString: String = isMinor ? String(string.dropLast()) : string
        
        guard let note = Note.parse(string: noteString, isMinor: isMinor) else {
            return nil
        }
        
        return Key(note: note, isMinor: isMinor)
    }
    
    init(note: Note, isMinor: Bool) {
        self.note = note
        self.isMinor = isMinor
    }
    
    var camelot: Int {
        return self.note.camelot
    }
    
    var isMajor: Bool {
        return !self.isMinor
    }
    
    var major: Key {
        return Key(note: self.note, isMinor: false)
    }
    
    var minor: Key {
        return Key(note: self.note, isMinor: true)
    }
    
    var description: String {
        return isMinor ? self.note.description.lowercased() : self.note.description
    }
}
