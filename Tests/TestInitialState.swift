//
//  TestInitialState.swift
//  
//
//  Created by Lukas Tenbrink on 04.02.19.
//

import XCTest

@testable import TenTunes

class TestInitialState: TenTunesTest {

    func testPlaylists() {
        XCTAssertEqual(Set(library[PlaylistRole.master].childrenList), Set([
            library[PlaylistRole.tags]
            ]), "Default playlists are wrong")
            
            XCTAssertEqual(library[PlaylistRole.tags].childrenList, [])
    }

    func testTracks() {
        XCTAssertEqual(library.allTracks(), [], "There are default tracks")
    }

}
