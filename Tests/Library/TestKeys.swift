//
//  TestKeys.swift
//  Tests
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestKeys: TenTunesTest {
    func testParsing() {
        XCTAssertEqual(Key.parse("Abm"),
                       Key(note: .Ab, isMinor: true)
        )
        
        XCTAssertEqual(Key.parse("Ab"),
                       Key(note: .Ab, isMinor: false)
        )
        
        XCTAssertEqual(Key.parse("C"),
                       Key(note: .C, isMinor: false)
        )

        XCTAssertEqual(Key.parse("Gm"),
                       Key(note: .G, isMinor: true)
        )

        
        XCTAssertEqual(Key.parse("Abmaj"),
                       Key(note: .Ab, isMinor: false)
        )

        XCTAssertEqual(Key.parse("Abmin"),
                       Key(note: .Ab, isMinor: true)
        )
    }
    
    func testOpenKey() {
        XCTAssertEqual(Key.parse("1A"),
                       Key(note: .Ab, isMinor: true)
        )
        
        XCTAssertEqual(Key.parse("8B"),
                       Key(note: .C, isMinor: false)
        )
        
        XCTAssertEqual(Key.parse("6A"),
                       Key(note: .G, isMinor: true)
        )
    }
    
    func testCamelot() {
        XCTAssertEqual(Key.parse("6m"),
                       Key(note: .Ab, isMinor: true)
        )
        
        XCTAssertEqual(Key.parse("1d"),
                       Key(note: .C, isMinor: false)
        )
        
        XCTAssertEqual(Key.parse("11m"),
                       Key(note: .G, isMinor: true)
        )
    }
    
    func testWrite() {
        XCTAssertEqual(Key(note: .Ab, isMinor: true).write,
                       "Abm"
        )
        
        XCTAssertEqual(Key(note: .C, isMinor: false).write,
                       "Cd"
        )
        
        XCTAssertEqual(Key(note: .G, isMinor: true).write,
                       "Gm"
        )
    }
}
