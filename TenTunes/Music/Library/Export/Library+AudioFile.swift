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
        
        guard let type = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
            NSWorkspace.shared.type(type, conformsToType: TrackPromise.utiType)
        else {
            // Probably not audiovisual content
            return nil
        }

        let track = Track(context: context)
        
         // Possibly temporary location, if it will be auto-moved after import
        track.path = url.absoluteString
        
        // If metadata is found, this will be overriden later
        track.title = url.deletingPathExtension().lastPathComponent
        
        context.insert(track)
        
        library.initialAdd(track: track, moveAction: moveAction)
        
        return track
    }
}
