//
//  Library+Export.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library {
    func startExport(completion: @escaping () -> Swift.Void) -> Bool {
        guard _exportsRequireUpdate, exportSemaphore.acquireNow() else {
            return false
        }
        
        performInBackground { mox in
            self.updateExports(in: mox)
            completion()
        }
        
        return true
    }
    
    func updateExports(in mox: NSManagedObjectContext) {
        let tracks = try! mox.fetch(Track.fetchRequest())
        // TODO Sort playlist by their parent / child tree
        let playlists = try! mox.fetch(Playlist.fetchRequest())
        
        _exportsRequireUpdate = false
        // Set this after fetching so no changes remain unexported
        
        exportSemaphore.signal()
    }
}
