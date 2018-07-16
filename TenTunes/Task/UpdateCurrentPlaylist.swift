//
//  UpdateCurrentPlaylist.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class CurrentPlaylistUpdater: Tasker {
    override var promise: Float? { return 0 }
    
    override func spawn() -> Task? {
        guard let trackController = ViewController.shared.trackController, let desired = trackController.desired, desired._changed, desired.semaphore.acquireNow() else {
            return nil
        }
        
        desired._changed = false
        return UpdateCurrentPlaylist(trackController: trackController, desired: desired)
    }
}

class UpdateCurrentPlaylist: Task {
    var trackController: TrackController
    var desired: PlayHistorySetup

    init(trackController: TrackController, desired: PlayHistorySetup) {
        self.trackController = trackController
        self.desired = desired
    }
    
    override var priority: Float { return 0 }
        
    override func execute() {
        let desired = self.desired
        
        Library.shared.performChildBackgroundTask { mox in
            let history = desired.playlist?.convert(to: mox) ?=> PlayHistory.init
            
            if let history = history {
                desired.filter ?=> history.filter
                desired.sort ?=> history.sort
            }
            
            DispatchQueue.main.async {
                history?.convert(to: Library.shared.viewContext)
                self.trackController.history = history ?? PlayHistory(playlist: Library.shared.allTracks)
                desired.isDone = !desired._changed
                
                self.finish()
            }
        }
    }
    
    override func finish() {
        super.finish()
        
        desired.semaphore.signal()
    }
}
