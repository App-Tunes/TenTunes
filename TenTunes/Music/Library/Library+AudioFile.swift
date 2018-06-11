//
//  FileImporter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 11.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library {
    func importTrack(url: URL) -> Track {
        let request = NSFetchRequest<Track>(entityName: "Track")
        request.predicate = NSPredicate(format: "path == %@", url.absoluteString)
        if let track = try! Library.shared.viewContext.fetch(request).first {
            return track
        }

        let track = Track(context: Library.shared.viewContext)
        
        track.path = url.absoluteString // Possibly temporary location
        track.title = url.lastPathComponent // Temporary title
        
        viewContext.insert(track)
        
        return track
    }
}
