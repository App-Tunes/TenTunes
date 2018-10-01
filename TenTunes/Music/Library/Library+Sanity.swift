//
//  Library+Sanity.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 20.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library {
    class CheckSanity: Task {
        let library: Library
        
        init(library: Library) {
            self.library = library
            super.init(priority: 2)
        }
        
        override var title: String { return "Check Sanity" }
        
        override var preventsQuit: Bool { return false }
        
        override func execute() {
            performChildBackgroundTask(for: library) { [unowned self] mox in
                self.check(in: mox)
                self.finish()
            }
        }
        
        func check(in context: NSManagedObjectContext) {
            // Copy array so it won't get modified while running over it
            let allPlaylists = Array(self.library.allPlaylists(in: context))
            let master = self.library.masterPlaylist.convert(to: context)!
            
            for playlist in allPlaylists {
                // All must go to master eventually
                if !Library.find(parent: master, of: playlist) {
                    master.addToChildren(playlist)
                }
            }
            
            if self.checkCanceled() { return }

            for case let playlist as PlaylistCartesian in allPlaylists {
                playlist.checkSanity(in: context)
            }
            
            if self.uncancelable() { return }
            
            let brokenVisualsRequest: NSFetchRequest<NSFetchRequestResult> = TrackVisuals.fetchRequest()
            brokenVisualsRequest.predicate = NSPredicate(format: "track == nil")
            try! context.execute(NSBatchDeleteRequest(fetchRequest: brokenVisualsRequest))

            try! context.save()
        }
    }
    
    static func find(parent: Playlist, of: Playlist) -> Bool {
        var playlist: Playlist? = of

        // No tree is larger than 100, and if it is... Fuck that tree
        // Nah, actually checks for infinite recursion among playlists
        for _ in 0..<100 {
            if playlist == parent {
                return true
            }
            playlist = playlist?.parent
        }
        
        return false
    }

    func considerSanity() {
        guard sanityChanged, sanitySemaphore.acquireNow() else {
            return
        }
        
        sanityChanged = false
        ViewController.shared.tasker.enqueue(task: CheckSanity(library: self))
        
        sanitySemaphore.signalAfter(seconds: 5)
    }
}
