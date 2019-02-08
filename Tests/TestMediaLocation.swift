//
//  TestMediaLocation.swift
//  Tests
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestMediaLocation : TestDatabase {
    override func setUp() {
        create(tracks: 3)
        
        for track in tracks {
            let file = String(format: "%@/%@.mp3", NSTemporaryDirectory(), UUID().uuidString)
            
            try! "sproing".write(toFile: file, atomically: true, encoding: .utf8)
            track.path = file
        }
    }
    
    func testLink() {
        for track in tracks {
            let old = track.resolvedURL!

            track.usesMediaDirectory = false
            library.mediaLocation.updateLocation(of: track)
            
            try! context.save()

            XCTAssertEqual(old, track.resolvedURL!)
            XCTAssertFileExists(at: track.resolvedURL!)
        }
    }
    
    func testMove() {
        for track in tracks {
            let old = track.resolvedURL!
            
            track.usesMediaDirectory = true
            library.mediaLocation.updateLocation(of: track)
            
            try! context.save()
            
            XCTAssertNotEqual(old, track.resolvedURL!)
            XCTAssertFileNotExists(at: old)
            XCTAssertFileExists(at: track.resolvedURL!)
        }
    }
    
    func testCopy() {
        for track in tracks {
            let old = track.resolvedURL!

            track.usesMediaDirectory = true
            library.mediaLocation.updateLocation(of: track, copy: true)
            
            try! context.save()

            XCTAssertNotEqual(old, track.resolvedURL!)
            XCTAssertFileExists(at: old)
            XCTAssertFileExists(at: track.resolvedURL!)
        }
    }
    
    func testDelete() {
        tracks[0].usesMediaDirectory = false
        tracks[1].usesMediaDirectory = true

        for track in tracks {
            library.mediaLocation.updateLocation(of: track)
            try! context.save()
        }
        
        let urls = tracks.map { $0.resolvedURL! }

        for track in tracks {
            context.delete(track)
            try! context.save()
        }
        
        XCTAssertFileExists(at: urls[0])
        XCTAssertFileNotExists(at: urls[1])
    }
}

