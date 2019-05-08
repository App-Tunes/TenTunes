//
//  TestTrackController.swift
//  Tests
//
//  Created by Lukas Tenbrink on 08.05.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestTrackController: TenTunesTest {
    var viewController: ViewController {
        return ViewController.shared
    }
    
    var trackController: TrackController {
        return viewController.trackController
    }
    
    override func setUp() {
        super.setUp()
        
        create(tracks: 2, groups: 0, tags: 1)
    }

    override func tearDown() {
        super.tearDown()
    }

    func selectLibrary() {
        viewController.playlistController.select(.master)
    }
    
    func select(playlist: Playlist) {
        viewController.playlistController.select(playlist: playlist)
    }
    
    func runViewUpdate() {
        // Usually set by spawn(task)
        trackController.desired._changed = false
        
        runSynchronousTask(UpdateCurrentPlaylist(trackController: trackController, desired: trackController.desired))
        
        XCTAssertTrue(trackController.desired.isDone)
    }
    
    func trackTitleAtRow(_ row: Int) -> String {
        let titleColumIdx = trackController._tableView.column(withIdentifier: TrackController.ColumnIdentifiers.title)
        
        guard let view = trackController._tableView.view(atColumn: titleColumIdx, row: row, makeIfNecessary: true) as? NSTableCellView else {
            fatalError("Unknown Row")
        }
        
        return view.textField!.stringValue
    }
    
    func isTrackOnScreen(_ track: Track) -> Bool {
        guard let supposedIndex = trackController.history.indexOf(track: track) else {
            return false
        }
        
        // If it should have a row, it SHOULD have a row
        XCTAssertEqual(trackTitleAtRow(supposedIndex), track.title)
        return true
    }

    func testLibrary() {
        selectLibrary()
        
        runViewUpdate()
        
        let numberOfRows = trackController._tableView.numberOfRows
        
        XCTAssertEqual(numberOfRows, tracks.count)
        XCTAssertEqual(numberOfRows, trackController.history.count)

        XCTAssertTrue(isTrackOnScreen(tracks[0]))
        XCTAssertTrue(isTrackOnScreen(tracks[1]))
    }

    func testTag() {
        select(playlist: tags[0])
        
        runViewUpdate()
        
        XCTAssertFalse(isTrackOnScreen(tracks[0]))
        XCTAssertFalse(isTrackOnScreen(tracks[1]))
        
        tags[0].addTracks(Array(tracks[0 ... 0]))

        runViewUpdate()

        XCTAssertTrue(isTrackOnScreen(tracks[0]))
        XCTAssertFalse(isTrackOnScreen(tracks[1]))
        
        tags[0].removeTracks(Array(tracks[0 ... 0]))
        
        runViewUpdate()

        XCTAssertFalse(isTrackOnScreen(tracks[0]))
        XCTAssertFalse(isTrackOnScreen(tracks[1]))
    }
}
