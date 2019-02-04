//
//  TestPlaylists.swift
//  Tests
//
//  Created by Lukas Tenbrink on 04.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestPlaylists: XCTestCase {
    var group: PlaylistFolder!
    
    override func setUp() {
        group = PlaylistFolder()
        Library.shared.masterPlaylist.addToChildren(group)
    }

    override func tearDown() {
        Library.shared.viewContext.delete(group)
        group = nil
    }

    func testTree() {
        let sub1 = PlaylistFolder()
        let sub2 = PlaylistFolder()
        
        group.addToChildren(sub1)
        group.addToChildren(sub2)
        
        let manual1 = PlaylistManual()
        sub1.addToChildren(manual1)

        
        let manual2 = PlaylistManual()
        let manual3 = PlaylistManual()
        group.addToChildren(manual2)
        group.addToChildren(manual3)
        
        XCTAssertEqual(group.childrenList, [
            sub1, sub2, manual2, manual3])

        XCTAssertEqual(sub1.childrenList, [manual1])
        XCTAssertEqual(sub2.childrenList, [])
    }
}
