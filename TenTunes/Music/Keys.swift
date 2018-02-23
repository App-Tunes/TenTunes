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

    static func parse(_ string: String, isMinor: Bool) -> Note? {
        switch string.lowercased() {
        case "a":
            return .A
        case "bb":
            return .Bb
        case "b":
            return .B
        case "c":
            return .C
        case "db":
            return .Db
        case "d":
            return .D
        case "eb":
            return .Eb
        case "e":
            return .E
        case "f":
            return .F
        case "gb":
            return .Gb
        case "g":
            return .G
        case "ab":
            return .Ab
        default:
            break
        }
        
        if let i = Int(string) {
            if i >= 1 && i <= 12 {
                return camelotWheel[(i - 1 + (isMinor ? 3 : 0)) % camelotWheel.count]
            }
        }
        
        return nil
    }
    
    func camelot(isMinor: Bool) -> Int {
        return (Note.camelotWheel.index(of: self)! + (isMinor ? 9 : 0)) % Note.camelotWheel.count
    }
    
    var description: String {
        switch self {
        case .A:
            return "A"
        case .Bb:
            return "B♭"
        case .B:
            return "B"
        case .C:
            return "C"
        case .Db:
            return "D♭"
        case .D:
            return "D"
        case .Eb:
            return "E♭"
        case .E:
            return "E"
        case .F:
            return "F"
        case .Gb:
            return "G♭"
        case .G:
            return "G"
        case .Ab:
            return "A♭"
        default:
            return ""
        }
    }
}

class Key {
    var note: Note
    var isMinor: Bool

    static func parse(_ string: String) -> Key? {
        let isMinor = string.last == "m"
        let noteString: String = isMinor ? String(string.dropLast()) : string
        
        guard let note = Note.parse(noteString, isMinor: isMinor) else {
            return nil
        }
        
        return Key(note: note, isMinor: isMinor)
    }
    
    init(note: Note, isMinor: Bool) {
        self.note = note
        self.isMinor = isMinor
    }
    
    var camelot: Int {
        return self.note.camelot(isMinor: isMinor)
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
    
    var description: NSAttributedString {
        let description = isMinor ? self.note.description.lowercased() : self.note.description
        let color = NSColor(hue: CGFloat(self.camelot - 1) / CGFloat(12), saturation: CGFloat(0.6), brightness: CGFloat(1.0), alpha: CGFloat(1.0))
        return NSAttributedString(string: description, attributes: [.foregroundColor: color])
    }
}