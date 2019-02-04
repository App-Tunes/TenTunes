//
//  TestInitialState.swift
//  
//
//  Created by Lukas Tenbrink on 04.02.19.
//

import XCTest

@testable import TenTunes

class TestInitialState: XCTestCase {

    func testPlaylists() {
        XCTAssertEqual(Set(Library.shared.masterPlaylist.childrenList), Set([
            Library.shared.tagPlaylist
            ]), "Default playlists are wrong")
            
            XCTAssertEqual(Library.shared.tagPlaylist.childrenList, [])
    }

    func testTracks() {
        XCTAssertEqual(Library.shared.allTracks.tracksList, [], "There are default tracks")
    }

}
