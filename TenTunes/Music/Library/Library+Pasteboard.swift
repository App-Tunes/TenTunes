//
//  Library+Pasteboard.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 11.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library {
    func writePlaylistID(of: Playlist) -> String {
        return of.objectID.uriRepresentation().absoluteString
    }
    
    func restoreFrom(playlistID: Any) -> Playlist? {
        if let uri = ((playlistID as? String) ?=> URL.init) ?? (playlistID as? URL), let id = persistentStoreCoordinator.managedObjectID(forURIRepresentation: uri) {
            return playlist(byId: id)
        }
        return nil
    }
    
    func writeTrack(_ track: Track, toPasteboarditem item: NSPasteboardItem) {
        item.setString(track.objectID.uriRepresentation().absoluteString, forType: Track.pasteboardType)
        
        if let url = track.resolvedURL {
            item.setString(url.absoluteString, forType: .fileURL)
        }
    }
    
    func readTrack(fromPasteboardItem item: NSPasteboardItem) -> Track? {
        if let idString = item.string(forType: Track.pasteboardType), let url = URL(string: idString), let id = persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
            return track(byId: id)
        }
        return nil
    }
    
    func writePlaylist(_ playlist: Playlist, toPasteboarditem item: NSPasteboardItem) {
        item.setString(playlist.objectID.uriRepresentation().absoluteString, forType: Playlist.pasteboardType)
    }
    
    func readPlaylist(fromPasteboardItem item: NSPasteboardItem) -> Playlist? {
        if let idString = item.string(forType: Playlist.pasteboardType), let url = URL(string: idString), let id = persistentStoreCoordinator.managedObjectID(forURIRepresentation: url) {
            return playlist(byId: id)
        }
        return nil
    }
}
