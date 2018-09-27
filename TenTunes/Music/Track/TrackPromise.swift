//
//  TrackPromise.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class TrackPromise {
    static let pasteboardTypes = [Track.pasteboardType, .fileURL]

    static func inside(pasteboard: NSPasteboard, from types: [NSPasteboard.PasteboardType], for library: Library) -> [TrackPromise]? {
        guard let type = pasteboard.availableType(from: types) else {
            return nil
        }
        
        switch type {
        case Track.pasteboardType:
            return (pasteboard.pasteboardItems ?? []).compactMap(library.readTrack)
                .map { .Existing($0) }
        case .fileURL:
            let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as! [NSURL]
            return urls.map { .File(url: $0 as URL, library: library) }
        default:
            return nil
        }
    }

    func fire() -> Track? { return nil }

    class Existing : TrackPromise {
        var track: Track?
        
        init(_ track: Track) {
            self.track = track
        }
        
        override func fire() -> Track? {
            return track
        }
    }
    
    class File : TrackPromise {
        var url: URL
        var library: Library
        
        init(url: URL, library: Library) {
            self.url = url
            self.library = library
        }
        
        override func fire() -> Track? {
            return library.import().track(url: url)
        }
    }
}
