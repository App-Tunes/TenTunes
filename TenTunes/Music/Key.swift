//
//  Keys.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 21.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import TunesLogic

import Defaults

@objc class Key : NSObject {
	static public let noteTitles = [
		"C", "D♭", "D", "Eb", "E",
		"F", "G♭", "G", "Ab", "A", "Bb", "B"
	]

	// TODO If possible, use key directly
    var key: MusicalKey

    static func parse(_ toParse: String) -> Key? {
		guard let key = MusicalKey.parse(toParse) else {
			return nil
		}
		
		return Key(key: key)
    }
    
    init(key: MusicalKey) {
		self.key = key
    }
    
    var openKey: Int {
		CircleOfFifths.openKey.index(of: key)
    }
    
    var camelot: Int {
		CircleOfFifths.camelot.index(of: key)
    }
	
	var isMinor: Bool {
		key.mode == .minor
	}
    
    var write: String {
		"\(Self.noteTitles[key.note.pitchClass])\(key.mode.shortTitle)"
    }
    
    override var description: String {
		let noteTitle = key.note.title
        
        var type: Defaults.Keys.InitialKeyWrite
        switch AppDelegate.defaults[.initialKeyDisplay] {
        case .custom(let custom): type = custom
        default: type = AppDelegate.defaults[.initialKeyWrite]
        }
        		
        switch type {
        case .german:
            return isMinor ? noteTitle.lowercased() : noteTitle
        case .openKey:
			return "\(self.openKey + 1)\(isMinor ? "A" : "B")"
        case .camelot:
			return "\(self.camelot + 1)\(isMinor ? "d" : "m")"
        case .english:
            return isMinor ? noteTitle + "m" : noteTitle
        }
    }
    
    @objc dynamic var attributes: [NSAttributedString.Key : Any]? {
        let color = NSColor(
            hue: (CGFloat(openKey - 1) / CGFloat(12) + 0.25).truncatingRemainder(dividingBy: 1),
            saturation: CGFloat(0.6),
            brightness: CGFloat(1.0), alpha: CGFloat(1.0)
        )

        return [.foregroundColor: color]
    }
    
    override func isEqual(_ object: Any?) -> Bool {
		(object as? Key)?.key == key
    }
}

extension Key : Comparable {    
    static func <(lhs: Key, rhs: Key) -> Bool {
        // Sort by note, then minorness
        lhs.openKey < rhs.openKey ? true
            : rhs.openKey < lhs.openKey ? false : lhs.isMinor
    }
    
    static func ==(lhs: Key, rhs: Key) -> Bool {
		lhs.key == rhs.key
    }
}

