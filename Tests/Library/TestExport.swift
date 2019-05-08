//
//  TestExport.swift
//  Tests
//
//  Created by Lukas Tenbrink on 16.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestExport: TenTunesTest {
    override func setUp() {
        super.setUp()
        create(tracks: 3, groups: 3, tags: 2)
    }
    
    func testLibrary() {
        let manual = PlaylistManual(context: context)
        manual.name = "Manual"
        manual.addTracks(tracks)
        groups[0].addToChildren(manual)
        
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Copy")
        guard let other = library.export(context).remoteLibrary([groups[1], manual, tags[0]], to: exportURL, pather: library.mediaLocation.pather()) else {
            XCTFail("Failed remote library creation")
            return
        }
        
        // TODO Also try saving and loading
        
        other.viewContext.performAndWait {
            let otherTracks = other.allTracks()
            
            XCTAssertEqual(otherTracks.count, 3)
            XCTAssert(otherTracks.contains { $0.title == "Track 0" })
            XCTAssert(otherTracks.contains { $0.title == "Track 1" })
            XCTAssert(otherTracks.contains { $0.title == "Track 2" })
            
            let otherRootPlaylists = other[PlaylistRole.playlists].childrenList
            XCTAssertEqual(otherRootPlaylists.count, 2)
            XCTAssert(otherRootPlaylists.contains { $0.name == "Group 0" })
            XCTAssert(otherRootPlaylists.contains { $0.name == "Group 1" })

            let otherPlaylists = other.allPlaylists()
            XCTAssertEqual(otherPlaylists.of(type: PlaylistManual.self).count, 2)
            XCTAssert(otherPlaylists.contains { $0.name == "Manual" })
            XCTAssert(otherPlaylists.contains { $0.name == "Tag 0" })

            let otherTags = other.allTags()
            XCTAssertEqual(otherTags.count, 1)
            XCTAssert(otherTags.contains { $0.name == "Tag 0" })
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: exportURL)
    }
}
