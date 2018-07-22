//
//  FetchTrackMetadata.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class FetchTrackMetadata: TrackTask {
    init(track: Track) {
        super.init(track: track, priority: 10)
    }
    
    override var title: String { return "Fetch Track Metadata" }

    // Will be auto-gathered each run anyway
    override var preventsQuit: Bool { return false }

    override func execute() {
        track.metadataFetched = true // So no other thread tries to enter
        
        Library.shared.performChildBackgroundTask { mox in
            mox.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
            
            let asyncTrack = mox.convert(self.track)
            
            asyncTrack.fetchMetadata()
            Library.shared.mediaLocation.updateLocation(of: self.track)
            
            try! mox.save()
            self.track.copyTransient(from: asyncTrack)
            
            self.finish() // TODO Low priority and thus only one thread at once
        }
    }
}
