//
//  Library+Pasteboard.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 11.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library.Export {    
    func write(_ track: Track, toPasteboardItem item: NSPasteboardItem) {
        item.setString(stringID(of: track), forType: Track.pasteboardType)
        
        if let url = track.resolvedURL {
            item.setString(url.absoluteString, forType: .fileURL)
        }
    }
    
    func pasteboardItem(representing track: Track) -> NSPasteboardItem {
        let item = NSPasteboardItem()
        write(track, toPasteboardItem: item)
        return item
    }
    
    func write(_ playlist: Playlist, toPasteboardItem item: NSPasteboardItem) {
        item.setString(stringID(of: playlist), forType: Playlist.pasteboardType)
    }
    
    func pasteboardItem(representing playlist: Playlist) -> NSPasteboardItem {
        let item = NSPasteboardItem()
        write(playlist, toPasteboardItem: item)
        return item
    }
}

extension Library.Import {    
    func track(fromPasteboardItem item: NSPasteboardItem) -> Track? {
        if let idString = item.string(forType: Track.pasteboardType), let id = objectID(from: idString) {
            return library.track(byId: id)
        }
        return nil
    }

    func playlist(id: Any) -> Playlist? {
        if let idString = id as? String, let id = objectID(from: idString) {
            return library.playlist(byId: id)
        }
        return nil
    }
    
    func playlist(fromPasteboardItem item: NSPasteboardItem) -> Playlist? {
        if let idString = item.string(forType: Playlist.pasteboardType), let id = objectID(from: idString) {
            return library.playlist(byId: id)
        }
        return nil
    }
}
