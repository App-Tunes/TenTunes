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
        
        override var title: String { return "Update Exports" }
        
        override var preventsQuit: Bool { return false }
        
        override func execute() {
            library.performChildBackgroundTask { mox in
                self.check(in: mox)
                self.finish()
            }
        }
        
        func check(in context: NSManagedObjectContext) {
            // Copy array so it won't get modified while running over it
            let allPlaylists = Array(self.library.allPlaylists(in: context))
            let master = context.convert(self.library.masterPlaylist)
            
            for playlist in allPlaylists {
                // All must go to master eventually
                if !Library.find(parent: master, of: playlist) {
                    master.addToChildren(playlist)
                }
            }

            for case let playlist as PlaylistCartesian in allPlaylists {
                playlist.checkSanity(in: context)
            }

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
        guard sanitySemaphore.acquireNow() else {
            return
        }
        
        ViewController.shared.tasker.enqueue(task: CheckSanity(library: self))
        
        sanitySemaphore.signalAfter(seconds: 5)
    }
}
