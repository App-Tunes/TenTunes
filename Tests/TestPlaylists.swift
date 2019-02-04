//
//  TestPlaylists.swift
//  Tests
//
//  Created by Lukas Tenbrink on 04.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestPlaylists : TestDatabase {
    override func setUp() {
        create(tracks: 2, groups: 3)
    }

    func testTree() {
        let sub1 = PlaylistFolder(context: context)
        let sub2 = PlaylistFolder(context: context)
        
        groups[0].addToChildren(sub1)
        groups[0].addToChildren(sub2)
        
        let manual1 = PlaylistManual(context: context)
        sub1.addToChildren(manual1)
        
        
        let manual2 = PlaylistManual(context: context)
        let manual3 = PlaylistManual(context: context)
        groups[0].addToChildren(manual2)
        groups[0].addToChildren(manual3)
        
        XCTAssertEqual(groups[0].childrenList, [
            sub1, sub2, manual2, manual3])
        
        XCTAssertEqual(sub1.childrenList, [manual1])
        XCTAssertEqual(sub2.childrenList, [])
    }

    func testCartesian() {
        // Group 1
        
        let manual1_1 = PlaylistManual(context: context)
        manual1_1.addToTracks([tracks[0], tracks[1]])
        groups[0].addToChildren(manual1_1)
        let manual1_2 = PlaylistManual(context: context)
        groups[0].addToChildren(manual1_2)

        // Group 2
        
        let manual2_1 = PlaylistManual(context: context)
        manual2_1.addToTracks(tracks[0])
        groups[1].addToChildren(manual2_1)
        let manual2_2 = PlaylistManual(context: context)
        manual2_2.addToTracks(tracks[1])
        groups[1].addToChildren(manual2_2)
        
         // Cartesian
        
        let cartesian = PlaylistCartesian(context: context)
        cartesian.rules.tokens.append(CartesianRules.Token.Folder(playlist: groups[0]))
        cartesian.rules.tokens.append(CartesianRules.Token.Folder(playlist: groups[1]))
        groups[2].addToChildren(cartesian)
        
        cartesian.checkSanity(in: context)

        let expectedTokens: [[SmartPlaylistRules.Token]] = [
            [.InPlaylist(playlist: manual1_1, isTag: false), .InPlaylist(playlist: manual2_1, isTag: false)],
            [.InPlaylist(playlist: manual1_1, isTag: false), .InPlaylist(playlist: manual2_2, isTag: false)],
        ]
        XCTAssertEqual(cartesian.childrenList.map { ($0 as! PlaylistSmart).rrules.tokens }, expectedTokens)
        
        XCTAssertEqual(cartesian.childrenList.map { $0.tracksList }, [
            [tracks[0]], [tracks[1]]
            ])
    }
}
