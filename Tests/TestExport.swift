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
        // TODO Tags don't work yet
        create(tracks: 3, groups: 2, tags: 0)
    }
    
    func testLibrary() {
        tracks[0].title = "Track0"
        tracks[1].title = "Track1"
        tracks[2].title = "Track2"
        
        groups[0].name = "Group0"
        groups[1].name = "Group1"

        let manual = PlaylistManual(context: context)
        manual.name = "Manual"
        manual.addTracks(tracks)
        groups[0].addToChildren(manual)
        
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Copy")
        library.export(context).remoteLibrary(groups + [manual], to: exportURL, pather: library.mediaLocation.pather())
        
        let other = Library(name: "TenTunes", at: exportURL, create: false)!
        
        other.viewContext.performAndWait {
            let otherTracks = other.allTracks.tracksList
            
            XCTAssertEqual(otherTracks.count, 3)
            XCTAssert(otherTracks.contains { $0.title == "Track0" })
            XCTAssert(otherTracks.contains { $0.title == "Track1" })
            XCTAssert(otherTracks.contains { $0.title == "Track2" })
            
            let otherPlaylists = other.allPlaylists()
            XCTAssert(otherPlaylists.contains { $0.name == "Group0" })
            XCTAssert(otherPlaylists.contains { $0.name == "Group1" })
            XCTAssert(otherPlaylists.contains { $0.name == "Manual" })
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: exportURL)
    }
}
