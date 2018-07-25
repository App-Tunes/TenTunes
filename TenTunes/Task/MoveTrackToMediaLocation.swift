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
    }
    
    override var title: String { return "\(copy ? "Copy" : "Move") Track To Media Directory" }
    
    override func execute() {
        Library.shared.performChildBackgroundTask { mox in
            guard let track = mox.convert(self.track) else {
                self.finish()
                return
            }
            
            guard !track.usesMediaDirectory else {
                self.finish()
                return
            }
            
            track.usesMediaDirectory = true
            Library.shared.mediaLocation.updateLocations(of: [track], copy: self.copy)
            
            self.finish()
            return
        }
    }
}
