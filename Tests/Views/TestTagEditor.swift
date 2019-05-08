//
//  TestTagEditor.swift
//  Tests
//
//  Created by Lukas Tenbrink on 08.05.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import XCTest

@testable import TenTunes

class TestTagEditor: TestTrackController {
    var trackEditor: TrackEditor {
        return trackController.trackEditor
    }
    
    var tagEditor: TagEditor {
        return trackEditor.tagEditor
    }
    
    var shownTags: [Playlist] {
        return tagEditor.viewTags.caseLet(TagEditor.ViewableTag.tag)
    }
    
    func select(track: Track) {
        selectLibrary()
        
        trackController.select(tracks: [track])
        trackController.trackEditorGuard.isHidden = false
    }
    
    func testTagUpdates() {
        select(track: tracks[0])
        
        XCTAssertEqual(shownTags, [])
        
        tags[0].addTracks(Array(tracks[0 ... 0]), above: nil)
        try! context.save()
        
        XCTAssertEqual(shownTags.count, 1)
        XCTAssertEqual(shownTags, [tags[0]])

        tags[0].removeTracks(Array(tracks[0 ... 0]))
        try! context.save()
        
        XCTAssertEqual(shownTags, [])
    }
}
