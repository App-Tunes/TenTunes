//
//  TrackController+Pasteboard.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 11.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

import AVFoundation

extension TrackController {
    var pasteboardTypes: [NSPasteboard.PasteboardType] {
        return TrackPromise.pasteboardTypes
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        Library.shared.writeTrack(history.track(at: row)!, toPasteboarditem: item)
        return item
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard let promises = TrackPromise.inside(pasteboard: info.draggingPasteboard(), for: Library.shared) else {
            return []
        }
        
        guard mode != .title else {
            // Either we drop below or on existing track, or we don't have a track yet
            return row == 1 || dropOperation == .on || history.count == 0 ? .link : []
        }
        
        guard dropOperation == .above else {
            return [] // What exactly do we drop ON tracks?
        }

        guard mode != .queue else {
            return .link // Any track can be added to queue
        }
        
        // We are a trackslist and thus need to be reorderable and unsorted
        guard (history.playlist as? ModifiablePlaylist)?.supports(action: .reorder) ?? false, history.isUnsorted else {
            return []
        }
        
        // Any existing track inside a trackslist is moved there
        return promises.anySatisfy { $0 is TrackPromise.Existing } ? .move : .link
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let promises = TrackPromise.inside(pasteboard: info.draggingPasteboard(), for: Library.shared) else {
            return false
        }

        let tracks = promises.compactMap { $0.fire() }
        
        if mode == .queue {
            let tracksBefore = history.tracks
            
            if (info.draggingSource() as AnyObject) === _tableView {
                history.rearrange(tracks: tracks, before: row)
            }
            else {
                history.insert(tracks: tracks, before: row)
            }
            
            _tableView.animateDifference(from: tracksBefore, to: history.tracks)
        }
        else if mode == .title {
            let player = ViewController.shared.player
            let history = player.history
            
            if dropOperation == .on {
                player.enqueue(tracks: tracks)
                if history.playingIndex >= 0 { history.remove(indices: [history.playingIndex]) }
                player.play(at: history.playingIndex, in: nil) // Reload track
            }
            else {
                player.enqueue(tracks: tracks)

                if self.history.count == 0 {
                    // User added this probably to play it
                    player.play(at: min(history.count - 1, history.playingIndex + 1), in: nil)
                }
            }
        }
        else if mode == .tracksList {
            let playlist = (history.playlist as! ModifiablePlaylist)
            
            guard playlist.confirm(action: .reorder) else {
                return false
            }
            
            playlist.addTracks(tracks, above: row)
            try! Library.shared.viewContext.save()
        }
        
        return true
    }    
}

extension TrackController: NSDraggingDestination {
    var acceptsGeneralDrag: Bool {
        guard let playlist = history.playlist as? ModifiablePlaylist, playlist.supports(action: .add), !playlist.supports(action: .reorder) else {
            return false
        }
        
        return true
    }
    
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard acceptsGeneralDrag else {
            return .generic
        }
        
        dragHighlightView.isReceivingDrag = true
        return .link
    }
    
    func draggingEnded(_ sender: NSDraggingInfo) {
        dragHighlightView.isReceivingDrag = false
    }
    
    func draggingExited(_ sender: NSDraggingInfo?) {
        dragHighlightView.isReceivingDrag = false
    }
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard acceptsGeneralDrag else {
            return false
        }

        let pasteboard = sender.draggingPasteboard()
        
        let parent = history.playlist
        
        if let promises = TrackPromise.inside(pasteboard: pasteboard, for: Library.shared) {
            guard (parent as! ModifiablePlaylist).confirm(action: .add) else {
                return false
            }
            
            let tracks = promises.compactMap { $0.fire() }
            (parent as! ModifiablePlaylist).addTracks(tracks)
            return true
        }
        
        return false
    }
}
