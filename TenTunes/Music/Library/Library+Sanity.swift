//
//  Library+Sanity.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 20.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library {
    class DynamicallyAdapt: Task {
        let library: Library

        init(library: Library) {
            self.library = library
            super.init(priority: 2)
        }
        
        override var title: String { return "Magically Adapt" }
        
        override var preventsQuit: Bool { return false }
        
        override func execute() {
            super.execute()
            
            performChildTask(for: library) { [unowned self] mox in
                self.adapt(in: mox)
                self.finish()
            }
        }
        
        func adapt(in context: NSManagedObjectContext) {
            // Copy array so it won't get modified while running over it
            let allPlaylists = Array(library.allPlaylists(in: context))
            
            for case let playlist as PlaylistCartesian in allPlaylists {
                playlist.checkSanity(in: context)
            }
            
            try! context.save()
        }
    }
    
    class CheckSanity: Task {
        let library: Library
        
        init(library: Library) {
            self.library = library
            super.init(priority: 2)
        }
        
        override var title: String { return "Check Sanity" }
        
        override var preventsQuit: Bool { return false }
        
        override func execute() {
            super.execute()
            
            performChildTask(for: library) { [unowned self] mox in
                self.check(in: mox)
                self.finish()
            }
        }
        
        func check(in context: NSManagedObjectContext) {
            // Copy array so it won't get modified while running over it
            let allPlaylists = Array(library.allPlaylists(in: context))
            let master = library[PlaylistRole.master, in: context]
            let defaultPlaylist = library[PlaylistRole.playlists, in: context]

            if master.parent != nil { master.parent = nil }
            
            for playlist in allPlaylists where playlist != master {
                if !library.inLegalSpot(playlist: playlist, master: master) {
                    let parent = library.role(of: playlist) == nil ? defaultPlaylist : master
                    parent.addToChildren(playlist)
                }
            }

            if self.uncancelable() { return }
            
            let brokenVisualsRequest: NSFetchRequest<NSFetchRequestResult> = TrackVisuals.fetchRequest()
            brokenVisualsRequest.predicate = NSPredicate(format: "track == nil")
            try! context.execute(NSBatchDeleteRequest(fetchRequest: brokenVisualsRequest))

            try! context.save()
        }
    }
    
    func inLegalSpot(playlist: Playlist, master: PlaylistFolder) -> Bool {
        // All must be some child of master
        guard Library.find(parent: master, of: playlist) else {
            return false
        }
        
        // Only special playlists allowed in master, but nowhere else
        guard (role(of: playlist) != nil) == (playlist.parent == master) else {
            return false
        }
        
        return true
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

    func considerAdapting() {
        guard dynamicAdaptNeeded, adaptSemaphore.acquireNow() else {
            return
        }
        
        dynamicAdaptNeeded = false
        ViewController.shared.tasker.enqueue(task: DynamicallyAdapt(library: self))
        
        adaptSemaphore.signalAfter(seconds: 5)
    }
    
    func checkSanity() {
        ViewController.shared.tasker.enqueue(task: CheckSanity(library: self))
    }
}
