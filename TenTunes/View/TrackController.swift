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
    
    @IBOutlet weak var _sortLabel: NSTextField!
    @IBOutlet weak var _sortBar: NSView!
    
    var _sortButtons: [NSButton] = []
    var _sortTitle: NSButton!
    var _sortKey: NSButton!
    var _sortBPM: NSButton!

    var playTrack: ((Track, Int) -> Swift.Void)?
    
    var history: PlayHistory! {
        didSet {
            history.textFilter = _searchField.stringValue.count > 0 ? _searchField.stringValue : nil
            _tableView.reloadData()
        }
    }
    
    func addSearchBarItem(title: String, previous: NSView) -> NSButton {
        let button = NSButton()
        button.title = title
        button.bezelStyle = .rounded
        button.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)

        button.translatesAutoresizingMaskIntoConstraints = false // !!!!!!!!!!
        
        button.setButtonType(.onOff)
//        button.state = .off
        
        button.target = self
        button.action = #selector(TrackController.filterPressed)
        
        _sortBar.addSubview(button)

        button.widthAnchor.constraint(equalToConstant: 100.0).isActive = true
        button.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: 8.0).isActive = true
        button.centerYAnchor.constraint(equalTo: _sortBar.centerYAnchor, constant: 0.0).isActive = true
        
        _sortButtons.append(button)
        
        return button
    }
    
    override func awakeFromNib() {
        _searchBarHeight.constant = CGFloat(0)
        _searchField.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        _searchBarClose.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        
        _sortTitle = addSearchBarItem(title: "Title", previous: _sortLabel)
        _sortKey = addSearchBarItem(title: "Key", previous: _sortTitle)
        _sortBPM = addSearchBarItem(title: "BPM", previous: _sortKey)

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
        if let url = track.url { // TODO Disable Button if we can't find the url
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
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
    
    @IBAction func filterPressed(_ sender: Any?) {
        guard let sender = sender as? NSButton else {
            return
        }
        
        if sender.state == .off {
            history.reorder(sort: nil)
            _tableView.reloadData()
            
            return
        }
        
        switch sender {
        case _sortTitle:
            history.reorder { $0.rTitle < $1.rTitle }
        case _sortKey:
            history.reorder { ($0.key?.camelot ?? 50) < ($1.key?.camelot ?? 50)  }
        case _sortBPM:
            history.reorder { ($0.bpm ?? 500) < ($1.bpm ?? 500)  }
        default:
            break
        }
        
        _tableView.reloadData()

        for other in _sortButtons where other !== sender {
            other.state = .off
        }
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
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        if let track = history.viewed(at: row) {
            let exists = track.url != nil
            if !exists {
                rowView.backgroundColor = NSColor.black
            }
        }
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
