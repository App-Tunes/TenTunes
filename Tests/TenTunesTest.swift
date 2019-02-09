//
//  TestDatabase.swift
//  Tests
//
//  Created by Lukas Tenbrink on 04.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

func XCTAssertFileExists(at url: URL) {
    XCTAssert(FileManager.default.fileExists(atPath: url.path), String(format: "File doesn't exist: %@", url.path))
}

func XCTAssertFileNotExists(at url: URL) {
    XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), String(format: "File exists: %@", url.path))
}

class TenTunesTest: XCTestCase {
    var tracks: [Track] = []
    var groups: [PlaylistFolder] = []
    var tags: [PlaylistManual] = []

    var context: NSManagedObjectContext {
        return Library.shared.viewContext
    }
    
    var library: Library {
        return Library.shared
    }
    
    func create(tracks: Int = 0, groups: Int = 0, tags: Int = 0) {
        self.tracks = (0 ..< tracks).map { _ in
            Track(context: self.context)
        }

        self.groups = (0 ..< groups).map { _ in
            let group = PlaylistFolder(context: self.context)
            self.library.masterPlaylist.addToChildren(group)
            return group
        }
        
        self.tags = ((0 ..< tags).map { _ in
            let tag = PlaylistManual(context: self.context)
            self.library.tagPlaylist.addToChildren(tag)
            return tag
        })
        
        try! context.save()
    }
    
    override func setUp() {
        if Library.shared.directory.deletingLastPathComponent() != FileManager.default.temporaryDirectory {
            fatalError("Library is not temp directory")
        }

        if Library.shared.mediaLocation.directory.deletingLastPathComponent().deletingLastPathComponent() != FileManager.default.temporaryDirectory {
            fatalError("Media Directory is not temp directory")
        }

        if AppDelegate.defaults.bool(forKey: "WelcomeWindow") {
            fatalError("Welcome Window consumed! Most likely wrong user defaults!")
        }
    }

    override func tearDown() {
        context.delete(all: groups)
        groups = []
        
        context.delete(all: tracks)
        tracks = []
        
        context.delete(all: tags)
        tags = []
        
        try! context.save()
    }
}
