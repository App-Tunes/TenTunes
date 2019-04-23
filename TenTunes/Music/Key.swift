//
//  Keys.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 21.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import Defaults

enum Note {
    case A, Bb, B, C, Db, D, Eb, E, F, Gb, G, Ab
    
    static var camelotWheel: [Note] = [.C, .G, .D, .A, .E, .B, .Gb, .Db, .Ab, .Eb, .Bb, .F]
    static var order: [Note] = [.A, .Bb, .B, .C, .Db, .D, .Eb, .E, .F, .Gb, .G, .Ab]

    static func parse(_ string: String) -> Note? {
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
        
        return nil
    }
    
    static func from(openKey: Int, isMinor: Bool) -> Note? {
        return Note.from(camelot: toCamelot(openKey: openKey), isMinor: isMinor)
    }
    
    static func from(camelot: Int, isMinor: Bool) -> Note? {
        guard camelot >= 1 && camelot <= 12 else {
            return nil
        }
        
        return Note.camelotWheel[((camelot - 1) + (isMinor ? 3 : 0)) % Note.camelotWheel.count]
    }
    
    static func toCamelot(openKey: Int) -> Int {
        if openKey < 1 || openKey > 12 { return 0 }
        return ((openKey - 1 + 5) % 12) + 1
    }
    
    static func toOpenKey(camelot: Int) -> Int {
        if camelot < 1 || camelot > 12 { return 0 }
        return ((camelot - 1 + 7) % 12) + 1
    }
    
    func openKey(isMinor: Bool) -> Int {
        return Note.toOpenKey(camelot: camelot(isMinor: isMinor))
    }
    
    func camelot(isMinor: Bool) -> Int {
        return ((Note.camelotWheel.firstIndex(of: self)! + (isMinor ? 9 : 0)) % Note.camelotWheel.count) + 1
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
        return description.replacingOccurrences(of: "♭", with: "b")
    }
}

@objc class Key : NSObject {
    static let suffices = [
        ("maj", false),
        ("min", true),
        ("d", false),
        ("m", true),
    ]

    var note: Note
    var isMinor: Bool

    static func parse(_ toParse: String) -> Key? {
        if toParse.count == 0 {
            return nil
        }
        let string = toParse.lowercased()

        var noteString = string
        var isMinor = false
        if string.count >= 2 {
            if string.last == "a" || string.last == "b", let number = Int(string.dropLast()) {
                // Open Key
                isMinor = string.last == "a"
                guard let note = Note.from(openKey: number, isMinor: isMinor) else {
                    return nil
                }
                
                return Key(note: note, isMinor: isMinor)
            }
            
            if let suffix = Key.suffices.filter({ string.hasSuffix($0.0) }).first {
                noteString = String(string.dropLast(suffix.0.count))
                isMinor = suffix.1
            }
            
            if let number = Int(noteString) {
                // Camelot
                guard let note = Note.from(camelot: number, isMinor: isMinor) else {
                    return nil
                }
                
                return Key(note: note, isMinor: isMinor)
            }
        }

        guard let note = Note.parse(noteString) else {
            return nil
        }
        
        return Key(note: note, isMinor: isMinor)
    }
    
    init(note: Note, isMinor: Bool) {
        self.note = note
        self.isMinor = isMinor
    }
    
    var openKey: Int {
        return note.openKey(isMinor: isMinor)
    }
    
    var camelot: Int {
        return note.camelot(isMinor: isMinor)
    }
    
    var isMajor: Bool {
        return !isMinor
    }
    
    var major: Key {
        return Key(note: note, isMinor: false)
    }
    
    var minor: Key {
        return Key(note: note, isMinor: true)
    }
    
    var write: String {
        return note.write + (isMinor ? "m" : "d")
    }
    
    override var description: String {
        var description = note.description
        
        var type: Defaults.Keys.InitialKeyWrite
        switch AppDelegate.defaults[.initialKeyDisplay] {
        case .custom(let custom): type = custom
        default: type = AppDelegate.defaults[.initialKeyWrite]
        }
        
        switch type {
        case .german:
            return isMinor ? description.lowercased() : description
        case .openKey:
            return "\(((note.openKey(isMinor: isMinor) + 7) % 12) + 1)\(isMinor ? "A" : "B")"
        case .camelot:
            return "\(((note.openKey(isMinor: isMinor) + 7) % 12) + 1)\(isMinor ? "d" : "m")"
        case .english:
            return isMinor ? description + "m" : description
        }
    }
    
    @objc dynamic var attributes: [NSAttributedString.Key : Any]? {
        let color = NSColor(hue: CGFloat(openKey - 1) / CGFloat(12), saturation: CGFloat(0.6), brightness: CGFloat(1.0), alpha: CGFloat(1.0))

        return [.foregroundColor: color]
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Key else {
            return false
        }
        return note == other.note
            && isMinor == other.isMinor
    }
}

extension Key : Comparable {    
    static func <(lhs: Key, rhs: Key) -> Bool {
        // Sort by note, then minorness
        return lhs.openKey < rhs.openKey ? true
            : rhs.openKey < lhs.openKey ? false : lhs.isMinor
    }
    
    static func ==(lhs: Key, rhs: Key) -> Bool {
        return lhs.note == rhs.note && lhs.isMinor == rhs.isMinor
    }
}

