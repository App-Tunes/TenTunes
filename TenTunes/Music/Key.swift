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
	
	public static let internalWriter: MusicalKeyWriter = MusicalKey.Writer(sharps: .sharp(stylized: false), mode: .shortVerbose)

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
		Self.internalWriter.write(key)
	}
	
	public static func writer(for type: Defaults.Keys.InitialKeyWrite, stylized: Bool) -> MusicalKeyWriter {
		switch type {
		case .german:
			return MusicalKey.GermanWriter(sharps: .flat(stylized: stylized))
		case .openKey:
			return CircleOfFifths.openKey
		case .camelot:
			return CircleOfFifths.camelot
		case .english:
			return MusicalKey.Writer(sharps: .flat(stylized: stylized), mode: .shortOnlyMinor, withSpace: false)
		}
	}
	
	public static var displayWriter: MusicalKeyWriter {
		switch AppDelegate.defaults[.initialKeyDisplay] {
		case .custom(let custom):
			return Self.writer(for: custom, stylized: true)
		default:
			return Self.writer(for: AppDelegate.defaults[.initialKeyWrite], stylized: true)
		}
	}
	
	public static var fileWriter: MusicalKeyWriter {
		Self.writer(for: AppDelegate.defaults[.initialKeyWrite], stylized: false)
	}

    override var description: String {
		Self.displayWriter.write(key)
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

