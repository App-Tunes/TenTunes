//
//  PlaylistPromise.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class PlaylistPromise {
    static let utiTypes = ["public.plain-text"]
    
    static let pasteboardTypes = [Playlist.pasteboardType, .fileURL]
    
    static func inside(pasteboard: NSPasteboard, for library: Library) -> [PlaylistPromise]? {
        guard let type = pasteboard.availableType(from: pasteboardTypes) else {
            return nil
        }
        
        switch type {
        case Playlist.pasteboardType:
            return (pasteboard.pasteboardItems ?? []).compactMap(library.readPlaylist)
                .map { .Existing($0) }
        case .fileURL:
            let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as! [NSURL]
            
            guard urls.allSatisfy({
                let type = try! NSWorkspace.shared.type(ofFile: $0.path!)
                return PlaylistPromise.utiTypes.anySatisfy { NSWorkspace.shared.type(type, conformsToType: $0) }
            }) else {
                return nil
            }
            
            return urls.map { .File(url: $0 as URL, library: library) }
        default:
            return nil
        }
    }
    
    func fire() -> Playlist? { return nil }
    
    class Existing : PlaylistPromise {
        var playlist: Playlist?
        
        init(_ playlist: Playlist) {
            self.playlist = playlist
        }
        
        override func fire() -> Playlist? {
            return playlist
        }
    }
    
    class File : PlaylistPromise {
        var url: URL
        var library: Library
        
        init(url: URL, library: Library) {
            self.url = url
            self.library = library
        }
        
        override func fire() -> Playlist? {
            return library.import().m3u(url: url)
        }
    }
}
