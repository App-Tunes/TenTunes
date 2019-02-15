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
        super.init(track: track, priority: 4)
        
        savesLibraryOnCompletion = true
    }
    
    override var title: String { return "Fetch Track Metadata" }
    
    override func execute() {
        super.execute()

        performChildBackgroundTask(for: library) { [unowned self] mox in
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
                if self.uncancelable() { return }
                
                self.library.mediaLocation.updateLocation(of: self.track)
            }
            
            try! mox.save()
            
            self.finish() // TODO Low priority and thus only one thread at once
        }
    }
}
