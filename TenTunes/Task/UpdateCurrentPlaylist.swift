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
    
    override func spawn(running: [Task]) -> Task? {
        guard let trackController = ViewController.shared.trackController, trackController.desired._changed else {
            return nil
        }
        
        let desired = trackController.desired
        
        let others = running.of(type: UpdateCurrentPlaylist.self).filter({ $0.trackController == trackController })
        guard others.isEmpty else {
            for other in others {
                other.cancel() // Cancel, but don't dare starting ourselves yet so we have at most one running at once (so we don't just start 100 by accident)
            }
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
        super.init(priority: 0)
    }
    
    override var title: String { return "Update Playlist View" }
    
    override var preventsQuit: Bool { return false }
    
    override var hidden: Bool { return true } // TrackController already shows loading anim
        
    override func execute() {
        super.execute()

        let desired = self.desired
        
        // Make sure to cache the results on the main thread if we use the biggest of them all
        (desired.playlist as? PlaylistLibrary)?.loadTracks()
        
        let filterTokens = trackController.filterBar.isOpen ? trackController.filterController.tokens : nil
        
        performChildBackgroundTask(for: Library.shared) { [unowned self] mox in
            let history = desired.playlist?.convert(to: mox) ?=> PlayHistory.init

            if self.checkCanceled() { return }

            if let history = history {
                desired.filter ?=> history.filter
                if self.checkCanceled() { return }
                
                let activeSort = desired.sort ?? (filterTokens ?=> UpdateCurrentPlaylist.defaultSort)
                activeSort ?=> history.sort
            }
            
            if self.uncancelable() { return }
            
            DispatchQueue.main.async {
                history?.convert(to: Library.shared.viewContext)
                self.trackController.history = history ?? PlayHistory(playlist: Library.shared.allTracks)
                desired.isDone = !desired._changed

                self.finish()
            }
        }
    }
    
    // TODO Find a better way (don't "hardcode" in here, maybe ask the tokens? Although technically we don't want to assume there ARE tokens
    static func defaultSort(for tokens: [SmartPlaylistRules.Token]) -> ((Track, Track) -> Bool)? {
        return (tokens.uniqueElement is SmartPlaylistRules.Token.InAlbum)
            ? Track.sortByAlbum
            : nil
    }
}
