//
//  ViewTest.swift
//  Tests
//
//  Created by Lukas Tenbrink on 09.05.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class ViewTest: TenTunesTest {
    var viewController: ViewController {
        return ViewController.shared
    }

    var trackController: TrackController {
        return viewController.trackController
    }

    override func tearDown() {
        // Reset gui states
        viewController.playlistController._outlineView.collapseItem(nil, collapseChildren: true)
        viewController.trackController.filterBar.close()
        
        super.tearDown()
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
    
    func runViewUpdate() {
        // Usually set by spawn(task)
        trackController.desired._changed = false
        
        runSynchronousTask(UpdateCurrentPlaylist(trackController: trackController, desired: trackController.desired))
        
        XCTAssertTrue(trackController.desired.isDone)
    }
}
