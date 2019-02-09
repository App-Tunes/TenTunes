//
//  TestPlayer.swift
//  Tests
//
//  Created by Lukas Tenbrink on 09.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestPlayer: TenTunesTest {

    override func setUp() {
        super.setUp()
        
        create(tracks: 8, groups: 1)
    }

    func testHistory() {
        let playlist = PlaylistManual(context: context)
        groups[0].addToChildren(playlist)
        
        playlist.addToTracks(tracks[0])
        playlist.addToTracks([tracks[1], tracks[2]])
        
        let history = PlayHistory(playlist: playlist)
        history.enqueue(tracks: [tracks[3]], at: .start)
        history.enqueue(tracks: [tracks[4], tracks[5]], at: .end)
        history.enqueue(tracks: [tracks[6], tracks[7]], at: .start)
        
        XCTAssertEqual(history.tracks, [
            tracks[6], tracks[7],
            tracks[3],
            tracks[4], tracks[5],
            tracks[0], 
            tracks[1], tracks[2],
            ])
    }
}
