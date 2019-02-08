//
//  Integrity.swift
//  Tests
//
//  Created by Lukas Tenbrink on 04.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestIntegrity: XCTestCase {
    func testLibraryLocation() {
        let container = Library.shared.directory.deletingLastPathComponent()
        XCTAssertEqual(container, FileManager.default.temporaryDirectory, "Library is not temp directory")
    }

    func testMediaLocation() {
        let container = Library.shared.mediaLocation.directory.deletingLastPathComponent().deletingLastPathComponent()
        XCTAssertEqual(container, FileManager.default.temporaryDirectory, "Media Directory is not temp directory")
    }
    
    func testUserDefaults() {
        XCTAssertEqual(AppDelegate.defaults.bool(forKey: "WelcomeWindow"), false, "Welcome Window consumed! Most likely wrong user defaults!")
    }
}
