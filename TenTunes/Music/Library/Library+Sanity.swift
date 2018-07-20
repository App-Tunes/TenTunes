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
            library.performBackgroundTask { mox in
                self.check(in: mox)
                self.finish()
            }
        }
        
        func check(in context: NSManagedObjectContext) {
            let allPlaylists = context.convert(self.library.allPlaylists)
            let master = context.convert(self.library.masterPlaylist)
            
            for case let playlist in allPlaylists {
                if playlist.parent == nil && playlist != master {
                    master.addToChildren(playlist)
                }
                
                if let playlist = playlist as? PlaylistCartesian {
                    playlist.checkSanity(in: context)
                }
            }
            
            try! context.save()
        }
    }

    func considerSanity() {
        guard sanitySemaphore.acquireNow() else {
            return
        }
        
        ViewController.shared.tasker.enqueue(task: CheckSanity(library: self))
        
        sanitySemaphore.signalAfter(seconds: 5)
    }
}
