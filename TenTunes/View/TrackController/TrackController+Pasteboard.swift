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
            return []
        }
        
        guard mode != .queue else {
            return dropOperation == .above ? .move : []
        }
        
        if dropOperation == .above, Library.shared.isEditable(playlist: history.playlist), history.isUnsorted {
            return .move
        }
        
        return []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard()
        guard let type = info.draggingPasteboard().availableType(from: tableView.registeredDraggedTypes) else {
            return false
        }

        var tracks: [Track] = []
        
        switch type {
        case Track.pasteboardType:
            tracks = (pasteboard.pasteboardItems ?? []).compactMap(Library.shared.readTrack)
        case .fileURL:
            let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
            tracks = (urls as! [NSURL]).map {FileImporter.importURL($0 as URL) }
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
        else if mode == .tracksList {
            (history.playlist as! PlaylistManual).addTracks(tracks, above: row)
            try! Library.shared.viewContext.save()
        }
        
        return true
    }    
}
