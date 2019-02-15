//
//  TestMediaLocation.swift
//  Tests
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestMediaLocation : TenTunesTest {
    override func setUp() {
        super.setUp()
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
    
    func testLocations() {
        for track in tracks {
            track.title = "Track"
            track.album = "Album"
            track.author = "Author"

            try! context.save()

            track.usesMediaDirectory = true
            library.mediaLocation.updateLocation(of: track)
            
            try! context.save()
        }
        
        let desired = library.mediaLocation.directory
            .appendingPathComponent("Author")
            .appendingPathComponent("Album")
            .appendingPathComponent("Track.mp3")
        XCTAssertFileExists(at: desired)
        
        XCTAssertEqual(desired, tracks[0].resolvedURL)
        XCTAssertNotEqual(tracks[0].resolvedURL, tracks[1].resolvedURL)
        
        XCTAssertFileExists(at: tracks[1].resolvedURL!)
        XCTAssertNotEqual(tracks[0].resolvedURL, tracks[2].resolvedURL)
        XCTAssertEqual(tracks[0].resolvedURL?.deletingLastPathComponent(), tracks[1].resolvedURL?.deletingLastPathComponent())

        XCTAssertFileExists(at: tracks[2].resolvedURL!)
        XCTAssertNotEqual(tracks[0].resolvedURL, tracks[2].resolvedURL)
        XCTAssertNotEqual(tracks[1].resolvedURL, tracks[2].resolvedURL)
        XCTAssertEqual(tracks[0].resolvedURL?.deletingLastPathComponent(), tracks[2].resolvedURL?.deletingLastPathComponent())
    }
    
    func testComplexLocation() {
        tracks[0].title = "Träck"
        tracks[0].album = "Älbüm»"
        tracks[0].author = "Äüthör"
        
        try! context.save()
        
        tracks[0].usesMediaDirectory = true
        library.mediaLocation.updateLocation(of: tracks[0])
        
        try! context.save()
        
        let desired = library.mediaLocation.directory
            .appendingPathComponent("Author")
            .appendingPathComponent("Album_")
            .appendingPathComponent("Track.mp3")
        XCTAssertFileExists(at: desired)
        XCTAssertEqual(desired, tracks[0].resolvedURL)
    }
}

