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
        XCTAssertEqual(Set(library.masterPlaylist.childrenList), Set([
            library.tagPlaylist
            ]), "Default playlists are wrong")
            
            XCTAssertEqual(library.tagPlaylist.childrenList, [])
    }

    func testTracks() {
        XCTAssertEqual(library.allTracks.tracksList, [], "There are default tracks")
    }

}
