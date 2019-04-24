//
//  FileImporter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 11.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library.Import {
    func track(url: URL) -> Track? {
        // TODO Hash all audio some time and then check the hashes on import to avoid duplicates
        if let track = library.allTracks().filter({ $0.resolvedURL == url }).first {
            return track
        }

        let track = Track(context: context)
        
         // Possibly temporary location, if it will be auto-moved after import
        track.path = url.absoluteString
        
        // If metadata is found, this will be overriden later
        track.title = url.deletingPathExtension().lastPathComponent
        
        context.insert(track)
        
        library.initialAdd(track: track)
        
        return track
    }
}
