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
        // TODO We set this, but if we quit in between it will not have been fetched
        track.metadataFetchDate = Date() // So no other thread tries to enter

        Library.shared.performChildBackgroundTask { mox in
            mox.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
            
            guard let asyncTrack = mox.convert(self.track) else {
                self.finish()
                return
            }
            
            if (try? asyncTrack.fetchMetadata()) == nil {
                // Reset
                asyncTrack.metadataFetchDate = nil
            }
            else {
                Library.shared.mediaLocation.updateLocation(of: self.track)
            }
            
            try! mox.save()
            
            self.finish() // TODO Low priority and thus only one thread at once
        }
    }
}
