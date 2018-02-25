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
    @IBOutlet weak var _searchField: NSSearchField!
    @IBOutlet var _searchBarHeight: NSLayoutConstraint!
    @IBOutlet weak var _searchBarClose: NSButton!
    
    var playTrack: ((Track, Int) -> Swift.Void)?
    
    var history: PlayHistory! {
        didSet {
            history.textFilter = _searchField.stringValue.count > 0 ? _searchField.stringValue : nil
            _tableView.reloadData()
        }
    }
    
    override func awakeFromNib() {
        _searchBarHeight.constant = CGFloat(0)
        _searchField.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        _searchBarClose.set(color: NSColor.white)

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.keyDown(with: $0)
        }
    }
    
    var visibleTracks: [TrackCellView] {
        var tracks: [TrackCellView] = []
        
        if let visibleRect = self._tableView.enclosingScrollView?.contentView.visibleRect {
            let visibleRows = self._tableView.rows(in: visibleRect)
            
            for row in visibleRows.lowerBound...visibleRows.upperBound {
                if history.size > row, let view = self._tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? TrackCellView {
                    tracks.append(view)
                }
            }
        }
        
        return tracks
    }
    
    var selectedTrack: Track? {
        let row = self._tableView.selectedRow
        return row >= 0 ? history.viewed(at: row) : nil
    }
    
    func playCurrentTrack() {
        if let selectedTrack = selectedTrack, let observer = playTrack {
            observer(selectedTrack, self._tableView.selectedRow)
        }
    }
    
    @IBAction func doubleClick(_ sender: Any) {
        let row = self._tableView.clickedRow
        
        if let playTrack = playTrack {
            if let track = history.viewed(at: row) {
                playTrack(track, row)
            }
        }
    }
    
    @IBAction func menuPlay(_ sender: Any) {
        self.doubleClick(sender)
    }
    
    @IBAction func menuShowInFinder(_ sender: Any) {
        let row = self._tableView.clickedRow
        let track = history.viewed(at: row)!
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
    
    func visibleView(to: Track) -> TrackCellView? {
        for visible in visibleTracks {
            if visible.track != nil && visible.track === to {
                return visible
            }
        }
        
        return nil
    }
    
    func update(view: TrackCellView?, with track: Track) {
        guard let view = view ?? visibleView(to: track) else {
            return
        }
        
        view.track = track
        view.textField?.stringValue = track.rTitle
        view.subtitleTextField?.stringValue = track.rSource
        view.lengthTextField?.stringValue = track.rLength
        view.imageView?.image = track.rArtwork
        view.key = track.rKey
        view.bpmTextField?.stringValue = track.bpm != nil ? Int(track.bpm!).description : nil ?? ""
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
        
        let track = history.viewed(at: row)!

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
        return history.size;
    }
}

extension TrackController: NSSearchFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        history.textFilter = _searchField.stringValue // Filtering is done in worker thread so reloading the data is too
    }
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        closeSearchBar(self)
    }
    
    @IBAction func openSearchBar(_ sender: Any) {
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _searchBarHeight.animator().constant = CGFloat(40)
        })
        _searchField.window?.makeFirstResponder(_searchField)
    }
    
    @IBAction func closeSearchBar(_ sender: Any) {
        history.textFilter = nil
        _tableView.reloadData()

        _searchField.resignFirstResponder()
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _searchBarHeight.animator().constant = CGFloat(0)
        })
    }
}
