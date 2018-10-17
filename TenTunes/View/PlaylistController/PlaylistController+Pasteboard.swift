//
//  PlaylistController+Pasteboard.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 11.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension PlaylistController {
    var pasteboardTypes: [NSPasteboard.PasteboardType] {
        return [Playlist.pasteboardType] + TrackPromise.pasteboardTypes
    }
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        let playlist = item as! Playlist
        
        let pbitem = NSPasteboardItem()
        Library.shared.writePlaylist(playlist, toPasteboarditem: pbitem)
        return pbitem
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        let pasteboard = info.draggingPasteboard()
        let playlist = item as? Playlist ?? masterPlaylist!

        if TrackPromise.inside(pasteboard: pasteboard, for: Library.shared) != nil {
            return ((playlist as? ModifiablePlaylist)?.supports(action: .add) ?? false) ? .link : []
        }

        guard let type = pasteboard.availableType(from: pasteboardTypes) else {
            return []
        }
        
        switch type {
        case Playlist.pasteboardType:
            // We can always rearrange, except into playlists
            let item = (item as? Playlist) ?? masterPlaylist!
            guard let parent = item as? PlaylistFolder, !parent.automatesChildren else {
                return []
            }
            let playlists = (pasteboard.pasteboardItems ?? []).compactMap(Library.shared.readPlaylist)
            guard playlists.allSatisfy({ Library.shared.isPlaylist(playlist: $0) || $0.parent == parent }) else {
                return []
            }
            // If any dropping playlist contains (or is) the new parent, don't drop
            guard playlists.noneSatisfy({Library.find(parent: $0, of: parent)}) else {
                return []
            }
            
            return playlists.anySatisfy { $0.parent!.automatesChildren } ? .copy : .move
        default:
            fatalError("Unhandled, but registered pasteboard type")
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pasteboard = info.draggingPasteboard()
        
        let parent = item as? Playlist ?? masterPlaylist!
        
        if let promises = TrackPromise.inside(pasteboard: pasteboard, for: Library.shared) {
            guard (parent as! ModifiablePlaylist).confirm(action: .add) else {
                return false
            }

            let tracks = promises.compactMap { $0.fire() }
            (parent as! ModifiablePlaylist).addTracks(tracks)
            return true
        }
        
        guard let type = pasteboard.availableType(from: pasteboardTypes) else {
            return false
        }

        switch type {
        case Playlist.pasteboardType:
            let playlists = (pasteboard.pasteboardItems ?? []).compactMap(Library.shared.readPlaylist)
                // Duplicate before dropping if we aren't supposed to edit the source
                .map { $0.parent!.automatesChildren ? $0.duplicate() : $0 }
            
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
