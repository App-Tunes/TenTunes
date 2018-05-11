//
//  PlaylistController+Pasteboard.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 11.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension PlaylistController {
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        let pbitem = NSPasteboardItem()
        Library.shared.writePlaylist(item as! Playlist, toPasteboarditem: pbitem)
        return pbitem
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        guard let type = info.draggingPasteboard().availableType(from: outlineView.registeredDraggedTypes) else {
            return []
        }
        
        switch type {
        case Track.pasteboardType:
            let playlist = item as? Playlist ?? masterPlaylist!
            return Library.shared.isEditable(playlist: playlist) ? .move : []
        case Playlist.pasteboardType:
            // We can always rearrange, except into playlists
            let playlist = item as? Playlist ?? masterPlaylist
            if !(playlist is PlaylistFolder) {
                return []
            }
            return .move
        default:
            fatalError("Unhandled, but registered pasteboard type")
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pasteboard = info.draggingPasteboard()
        
        guard let type = pasteboard.availableType(from: outlineView.registeredDraggedTypes) else {
            return false
        }
        
        let parent = item as? Playlist ?? masterPlaylist!
        
        switch type {
        case Track.pasteboardType:
            let tracks = (pasteboard.pasteboardItems ?? []).compactMap(Library.shared.readTrack)
            
            (parent as! PlaylistManual).addTracks(tracks)
            return true
        case Playlist.pasteboardType:
            let playlists = (pasteboard.pasteboardItems ?? []).compactMap(Library.shared.readPlaylist)
            
            for playlist in playlists {
                (parent as! PlaylistFolder).addPlaylist(playlist, above: index >= 0 ? index : nil)
            }
            break
        default:
            fatalError("Unhandled, but registered pasteboard type")
        }
        
        try! Library.shared.viewContext.save()
        
        return true
    }
}
