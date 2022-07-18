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

extension MusicalKey {
	public static let internalWriter: MusicalKeyWriter = MusicalKey.Writer(sharps: .sharp(stylized: false), mode: .shortVerbose)

    var openKey: Int {
		CircleOfFifths.openKey.index(of: self)
    }
    
    var camelot: Int {
		CircleOfFifths.camelot.index(of: self)
    }
	
	var isMinor: Bool {
		self.mode == .minor
	}
	
	var write: String {
		Self.internalWriter.write(self)
	}
	
	static func writer(for type: Defaults.Keys.InitialKeyWrite, stylized: Bool) -> MusicalKeyWriter {
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

    var description: String {
		Self.displayWriter.write(self)
    }
    
    var attributes: [NSAttributedString.Key : Any]? {
        let color = NSColor(
            hue: (CGFloat(openKey - 1) / CGFloat(12) + 0.25).truncatingRemainder(dividingBy: 1),
            saturation: CGFloat(0.6),
            brightness: CGFloat(1.0), alpha: CGFloat(1.0)
        )

        return [.foregroundColor: color]
    }
}

extension MusicalKey : Comparable {
    public static func <(lhs: MusicalKey, rhs: MusicalKey) -> Bool {
        // Sort by note, then minorness
        lhs.openKey < rhs.openKey ? true
            : rhs.openKey < lhs.openKey ? false : lhs.isMinor
    }
}

