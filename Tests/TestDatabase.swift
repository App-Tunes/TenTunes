//
//  TestDatabase.swift
//  Tests
//
//  Created by Lukas Tenbrink on 04.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestDatabase: XCTestCase {
    var tracks: [Track] = []
    var groups: [PlaylistFolder] = []

    var context: NSManagedObjectContext {
        return Library.shared.viewContext
    }
    
    var library: Library {
        return Library.shared
    }
    
    func create(tracks: Int, groups: Int) {
        self.tracks = (0 ..< tracks).map { _ in
            Track(context: self.context)
        }

        self.groups = (0 ..< groups).map { _ in
            let group = PlaylistFolder(context: self.context)
            self.library.masterPlaylist.addToChildren(group)
            return group
        }
        
        try! context.save()
    }
    
    override func setUp() {
        
    }

    override func tearDown() {
        context.delete(all: groups)
        groups = []
        
        context.delete(all: tracks)
        tracks = []
    }
}
