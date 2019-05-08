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

    func runViewUpdate() {
        // Usually set by spawn(task)
        trackController.desired._changed = false
        
        runSynchronousTask(UpdateCurrentPlaylist(trackController: trackController, desired: trackController.desired))
        
        XCTAssertTrue(trackController.desired.isDone)
    }

    func selectLibrary() {
        viewController.playlistController.select(.master)
        runViewUpdate()

        XCTAssertEqual(trackController.history.playlist.persistentID, library[PlaylistRole.library].persistentID)
    }
    
    func select(playlist: Playlist) {
        XCTAssertTrue(viewController.playlistController.select(playlist: playlist))
        runViewUpdate()
        
        XCTAssertEqual(trackController.history.playlist as? Playlist, playlist)
    }
    
    func trackTitleAtRow(_ row: Int) -> String {
        let titleColumIdx = trackController._tableView.column(withIdentifier: TrackController.ColumnIdentifiers.title)
        
        guard let view = trackController._tableView.view(atColumn: titleColumIdx, row: row, makeIfNecessary: true) as? NSTableCellView else {
            fatalError("Unknown Row")
        }
        
        return view.textField!.stringValue
    }
    
    enum TrackScreenStatus {
        case visible, missing, absent
    }
    
    func screenStatus(ofTrack track: Track) -> TrackScreenStatus {
        guard let supposedIndex = trackController.history.indexOf(track: track) else {
            // Playlist doesn't even contain it
            return .absent
        }
        
        // If it should have a row, it SHOULD have a row
        return trackTitleAtRow(supposedIndex) == track.title ? .visible : .missing
    }

    func testLibrary() {
        selectLibrary()
        
        let numberOfRows = trackController._tableView.numberOfRows
        
        XCTAssertEqual(numberOfRows, tracks.count)
        XCTAssertEqual(numberOfRows, trackController.history.count)

        XCTAssertEqual(screenStatus(ofTrack: tracks[0]), .visible)
        XCTAssertEqual(screenStatus(ofTrack: tracks[1]), .visible)
    }

    func testTag() {
        select(playlist: tags[0])
        
        XCTAssertEqual(screenStatus(ofTrack: tracks[0]), .absent)
        XCTAssertEqual(screenStatus(ofTrack: tracks[1]), .absent)
        
        tags[0].addTracks(Array(tracks[0 ... 0]))

        runViewUpdate()

        XCTAssertEqual(screenStatus(ofTrack: tracks[0]), .visible)
        XCTAssertEqual(screenStatus(ofTrack: tracks[1]), .absent)
        
        tags[0].removeTracks(Array(tracks[0 ... 0]))
        
        runViewUpdate()

        XCTAssertEqual(screenStatus(ofTrack: tracks[0]), .absent)
        XCTAssertEqual(screenStatus(ofTrack: tracks[1]), .absent)
    }
}
