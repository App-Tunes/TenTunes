//
//  TrackController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation

class TrackController: NSObject {
    @IBOutlet var _tableView: NSTableView!

    var playTrack: ((Track, Int) -> Swift.Void)?
    
    var playlist: Playlist! {
        didSet {
            _tableView.reloadData()
        }
    }
    
    override func awakeFromNib() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.keyDown(with: $0)
        }
    }
    
    var visibleTracks: [TrackCellView] {
        var tracks: [TrackCellView] = []
        
        if let visibleRect = self._tableView.enclosingScrollView?.contentView.visibleRect {
            let visibleRows = self._tableView.rows(in: visibleRect)
            
            for row in visibleRows.lowerBound...visibleRows.upperBound {
                if self.playlist.tracks.count > row, let view = self._tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? TrackCellView {
                    tracks.append(view)
                }
            }
        }
        
        return tracks
    }
    
    func playCurrentTrack() {
        let row = self._tableView.selectedRow
        
        if let playTrack = playTrack {
            playTrack(self.playlist.track(at: row)!, row)
        }
    }
    
    @IBAction func doubleClick(_ sender: Any) {
        let row = self._tableView.clickedRow
        
        if let playTrack = playTrack {
            playTrack(self.playlist.track(at: row)!, row)
        }
    }
    
    @IBAction func menuPlay(_ sender: Any) {
        self.doubleClick(sender)
    }
    
    @IBAction func menuShowInFinder(_ sender: Any) {
        let row = self._tableView.clickedRow
        let track = self.playlist.track(at: row)!
        NSWorkspace.shared.activateFileViewerSelecting([track.url!])
    }
    
    func keyDown(with event: NSEvent) -> NSEvent? {
        if Keycodes.enterKey.matches(event: event) || Keycodes.returnKey.matches(event: event) {
            self.playCurrentTrack()
        }
        else {
            return event
        }
        
        return nil
    }
    
    func update(view: TrackCellView, with track: Track) {
        view.track = track
        view.textField?.stringValue = track.rTitle
        view.subtitleTextField?.stringValue = track.rSource
        view.lengthTextField?.stringValue = track.rLength
        view.imageView?.image = track.rArtwork
        view.key = track.rKey
        view.bpmTextField?.stringValue = track.bpm?.description ?? ""
    }
}

extension TrackController: NSTableViewDelegate {
    fileprivate enum CellIdentifiers {
        static let NameCell = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        
        let track = self.playlist.tracks[row]

        if tableColumn == tableView.tableColumns[0] {
            if let view = tableView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? TrackCellView {
                update(view: view, with: track)
                return view
            }
        } else if tableColumn == tableView.tableColumns[1] {
            
        } else if tableColumn == tableView.tableColumns[2] {
            
        }
        
        return nil
    }
}

extension TrackController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.playlist.tracks.count;
    }
}
