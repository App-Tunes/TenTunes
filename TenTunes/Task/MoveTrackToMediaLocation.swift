//
//  MoveTrackToMediaLocation.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class MoveTrackToMediaLocation: TrackTask {
    var copy: Bool
    
    init(track: Track, copy: Bool) {
        self.copy = copy
        super.init(track: track, priority: 5)
        
        savesLibraryOnCompletion = true
    }
    
    override var title: String { return "\(copy ? "Copy" : "Move") Track To Media Directory" }
    
    override func execute() {
        super.execute()

        performChildTask(for: library) { [unowned self] mox in
            guard let track = mox.convert(self.track) else {
                return
            }
                        
            guard !track.usesMediaDirectory else {
                self.finish()
                return
            }
            
            // Make sure we know title, artist etc.
            guard (try? track.fetchMetadata()) != nil else {
                // Track might be broken. Don't move to whereever I guess
                self.finish()
                NSAlert.warning(title: "Failed to move to Media Directory", text: "Unknown Error")
                return
            }

            track.usesMediaDirectory = true
            self.library.mediaLocation.updateLocation(of: track, copy: self.copy)
            
            try! mox.save()
            
            self.finish()
            return
        }
    }
}
