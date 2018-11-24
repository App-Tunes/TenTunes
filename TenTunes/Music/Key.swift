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
        case "a#", "bb":
            return .Bb
        case "b":
            return .B
        case "c":
            return .C
        case "c#", "db":
            return .Db
        case "d":
            return .D
        case "d#", "eb":
            return .Eb
        case "e":
            return .E
        case "f":
            return .F
        case "f#", "gb":
            return .Gb
        case "g":
            return .G
        case "g#", "ab":
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
        }
    }

    var write: String {
        switch self {
        case .A:
            return "a"
        case .Bb:
            return "bb"
        case .B:
            return "b"
        case .C:
            return "c"
        case .Db:
            return "db"
        case .D:
            return "d"
        case .Eb:
            return "eb"
        case .E:
            return "e"
        case .F:
            return "f"
        case .Gb:
            return "gb"
        case .G:
            return "g"
        case .Ab:
            return "ab"
        }
    }
}

@objc class Key : NSObject {
    var note: Note
    var isMinor: Bool

    static func parse(_ string: String) -> Key? {
        if string.count == 0 {
            return nil
        }
        var noteString = string
        
        var isMinor = false
        if (string.last == "m" || string.last == "A") && string.count >= 2 {
            noteString = String(string.dropLast())
            isMinor = true
        }
        else if (string.last == "d" || string.last == "B") && string.count >= 2 {
            noteString = String(string.dropLast())
        }
        else if string.hasSuffix("min") {
            noteString = String(string.dropLast(3))
            isMinor = true
        }
        else if string.hasSuffix("maj") {
            noteString = String(string.dropLast(3))
        }

        guard let note = Note.parse(noteString, isMinor: isMinor) else {
            print("Failed to parse key: \(string)")
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
    
    var write: String {
        return note.write + (isMinor ? "m" : "d")
    }
    
    override var description: String {
        var description = note.description
        
        switch UserDefaults.standard.initialKeyDisplay {
        case .german:
            description = isMinor ? description.lowercased() : description
        case .camelot:
            description = "\(((note.camelot(isMinor: isMinor) + 7) % 12) + 1)\(isMinor ? "A" : "B")"
        default:
            description = isMinor ? description + "m" : description
        }

        return description
    }
    
    @objc dynamic var attributes: [NSAttributedString.Key : Any]? {
        let color = NSColor(hue: CGFloat(camelot - 1) / CGFloat(12), saturation: CGFloat(0.6), brightness: CGFloat(1.0), alpha: CGFloat(1.0))

        return [.foregroundColor: color]
    }
}

extension Key : Comparable {    
    static func <(lhs: Key, rhs: Key) -> Bool {
        // Sort by note, then minorness
        return lhs.camelot < rhs.camelot ? true
            : rhs.camelot < lhs.camelot ? false : lhs.isMinor
    }
    
    static func ==(lhs: Key, rhs: Key) -> Bool {
        return lhs.note == rhs.note && lhs.isMinor == rhs.isMinor
    }
}

