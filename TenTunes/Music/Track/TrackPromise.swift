//
//  TrackPromise.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class TrackPromise {
    static let utiType = "public.audiovisual-content"
    
    static let pasteboardTypes = [Track.pasteboardType, .fileURL]

    static func inside(pasteboard: NSPasteboard, for library: Library) -> [TrackPromise]? {
        guard let type = pasteboard.availableType(from: pasteboardTypes) else {
            return nil
        }
        
        switch type {
        case Track.pasteboardType:
            return (pasteboard.pasteboardItems ?? []).compactMap(library.import().track)
                .map { .Existing($0) }
        case .fileURL:
            let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as! [NSURL]
            
            guard urls.allSatisfy({
                let type = (try? NSWorkspace.shared.type(ofFile: $0.path!)) ?? "public.data"
                return NSWorkspace.shared.type(type, conformsToType: TrackPromise.utiType)
            }) else {
                return nil
            }
            
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
