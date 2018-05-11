//
//  FileImporter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 11.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class FileImporter {
    static func importURL(_ url: URL) -> Track {
        let track = Track()
        
        track.path = url.absoluteString
        track.title = url.lastPathComponent
        
        Library.shared.viewContext.insert(track)
        
        return track
    }
}
