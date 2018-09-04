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
        return [Track.pasteboardType, .fileURL]
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        Library.shared.writeTrack(history.track(at: row)!, toPasteboarditem: item)
        return item
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard mode != .title else {
            return row == 1 || dropOperation == .on ? .move : [] // Works for on and above 1
        }
        
        guard dropOperation == .above else {
            return [] // What exactly do we drop ON tracks?
        }
        
        guard mode != .queue else {
            return .move
        }
        
        if dropOperation == .above, (history.playlist as? ModifiablePlaylist)?.supports(action: .reorder) ?? false, history.isUnsorted {
            return .move
        }
        
        return []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard()
        guard let type = info.draggingPasteboard().availableType(from: pasteboardTypes) else {
            return false
        }

        var tracks: [Track] = []
        
        switch type {
        case Track.pasteboardType:
            tracks = (pasteboard.pasteboardItems ?? []).compactMap(Library.shared.readTrack)
        case .fileURL:
            let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
            tracks = (urls as! [NSURL]).compactMap { Library.shared.import().track(url: $0 as URL) }
        default:
            return false
        }
        
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
            let history = ViewController.shared.player.history
            let player = ViewController.shared.player
            
            if dropOperation == .on {
                player.enqueue(tracks: tracks)
                if history!.playingIndex >= 0 { history?.remove(indices: [history!.playingIndex]) }
                player.play(at: history!.playingIndex, in: nil) // Reload track
            }
            else {
                player.enqueue(tracks: tracks)
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
