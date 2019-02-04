//
//  TrackController+Tracks.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 01.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation

extension TrackController {
    enum CellIdentifiers {
        static let artwork = NSUserInterfaceItemIdentifier(rawValue: "artworkCell")
        static let staticArtwork = NSUserInterfaceItemIdentifier(rawValue: "staticArtworkCell")
        static let waveform = NSUserInterfaceItemIdentifier(rawValue: "waveformCell")
        static let title = NSUserInterfaceItemIdentifier(rawValue: "titleCell")
        static let combinedTitle = NSUserInterfaceItemIdentifier(rawValue: "combinedTitleCell")
        static let author = NSUserInterfaceItemIdentifier(rawValue: "authorCell")
        static let album = NSUserInterfaceItemIdentifier(rawValue: "albumCell")
        static let genre = NSUserInterfaceItemIdentifier(rawValue: "genreCell")
        static let bpm = NSUserInterfaceItemIdentifier(rawValue: "bpmCell")
        static let key = NSUserInterfaceItemIdentifier(rawValue: "keyCell")
        static let duration = NSUserInterfaceItemIdentifier(rawValue: "durationCell")
        static let dateAdded = NSUserInterfaceItemIdentifier(rawValue: "dateAddedCell")
        static let year = NSUserInterfaceItemIdentifier(rawValue: "yearCell")
    }
    
    enum ColumnIdentifiers {
        static let artwork = NSUserInterfaceItemIdentifier(rawValue: "artworkColumn")
        static let waveform = NSUserInterfaceItemIdentifier(rawValue: "waveformColumn")
        static let title = NSUserInterfaceItemIdentifier(rawValue: "titleColumn")
        static let author = NSUserInterfaceItemIdentifier(rawValue: "authorColumn")
        static let album = NSUserInterfaceItemIdentifier(rawValue: "albumColumn")
        static let genre = NSUserInterfaceItemIdentifier(rawValue: "genreColumn")
        static let bpm = NSUserInterfaceItemIdentifier(rawValue: "bpmColumn")
        static let key = NSUserInterfaceItemIdentifier(rawValue: "keyColumn")
        static let duration = NSUserInterfaceItemIdentifier(rawValue: "durationColumn")
        static let dateAdded = NSUserInterfaceItemIdentifier(rawValue: "dateAddedColumn")
        static let year = NSUserInterfaceItemIdentifier(rawValue: "yearColumn")
    }

    var selectedTrack: Track? {
        let row = self._tableView.selectedRow
        return row >= 0 ? history.track(at: row) : nil
    }
    
    func initTable() {
        _tableView.enterAction = #selector(enterAction(_:))
        _tableView.registerForDraggedTypes(pasteboardTypes)
        _tableView.setDraggingSourceOperationMask(.every, forLocal: false) // ESSENTIAL
        
        tableViewHiddenManager = .init(tableView: _tableView, defaultsKey: "trackColumnsHidden", ignore: [ColumnIdentifiers.title.rawValue])
        tableViewHiddenManager.titles[ColumnIdentifiers.artwork] = "Artwork"
        tableViewHiddenManager.titles[ColumnIdentifiers.waveform] = "Waveform"
        tableViewHiddenManager.start()
    }
    
    func playCurrentTrack() {
        if selectedTrack != nil {
            playTrack?(self._tableView.selectedRow, nil)
        }
    }
    
    @IBAction func enterAction(_ sender: Any) {
        playCurrentTrack()
    }
    
    @IBAction func doubleClick(_ sender: Any) {
        let row = _tableView.clickedRow
        
        if history.track(at: row) != nil {
            playTrack?(row, nil)
        }
    }
    
    func reload(track: Track) {
        if let row = history.indexOf(track: track) {
            // TODO Remove all
            _tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: [1])
        }
    }
    
    @IBAction func waveformViewClicked(_ sender: Any?) {
        if let view = sender as? WaveformView {
            if let row = view.superview ?=> _tableView.row, history.track(at: row) != nil {
                playTrack?(row, view.location)
            }
            
            view.location = nil
        }
    }
    
    func remove(indices: [Int]?) {
        guard let indices = indices else {
            return
        }
        
        guard mode == .tracksList else {
            let tracksBefore = history.tracks
            history.remove(indices: indices)
            _tableView.animateDifference(from: tracksBefore, to: history.tracks)
            return
        }
        
        let playlist = (history.playlist as! ModifiablePlaylist)
        
        guard playlist.confirm(action: .delete) else {
            return
        }
        
        playlist.removeTracks(indices.compactMap { history.track(at: $0) })
        // Don't reload data, we'll be updated in async
    }
    
    @IBAction func albumCoverClicked(_ sender: Any?) {
        let row = _tableView.row(for: sender as! NSView)
        let track = history.track(at: row)
        
        guard ViewController.shared.player.playing != track else {
            return
        }
        
        playTrack?(row, nil)
    }

}

extension TrackController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let track = history.track(at: row)!
        
        if tableColumn?.identifier == ColumnIdentifiers.artwork, let view = tableView.makeView(withIdentifier: mode != .title ? CellIdentifiers.artwork : CellIdentifiers.staticArtwork, owner: nil) {
            view.wantsLayer = true
            
            view.layer!.borderWidth = 1.0
            view.layer!.borderColor = NSColor.lightGray.cgColor.copy(alpha: CGFloat(0.333))
            view.layer!.cornerRadius = 3.0
            view.layer!.masksToBounds = true
            
            view.bind(.image, to: track, withKeyPath: \.artworkPreview, options: [.nullPlaceholder: Album.missingArtwork])
            
            if let button = view as? PlayImageView {
                button.isEnabled = true
                
                // TODO Too Omniscient?
                button.observe(track: track, playingIn: ViewController.shared.player)
                
                button.target = self
                button.action = #selector(albumCoverClicked)
            }
            
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.waveform, let view = tableView.makeView(withIdentifier: CellIdentifiers.waveform, owner: nil) as? WaveformView {
            // TODO When an analysis saves this is reloaded (and thus set instantly) rather than letting it animate further
            if track.analysis == nil {
                track.readAnalysis()
            }
            
            // Doesn't work from interface builder
            view.target = self
            view.action = #selector(waveformViewClicked)
            
            view.track = track
            view.setInstantly(analysis: track.analysis)
            
            view.observe(for: track, in: ViewController.shared.player)
            
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.title {
            if AppDelegate.defaults.trackCombinedTitleSource, let view = tableView.makeView(withIdentifier: CellIdentifiers.combinedTitle, owner: nil) as? TitleSubtitleCellView {
                view.textField?.bind(.value, to: track, withKeyPath: \.rTitle)
                view.subtitleTextField?.bind(.value, to: track, withKeyPath: \.rSource)
                return view
            }
            else if let view = tableView.makeView(withIdentifier: CellIdentifiers.title, owner: nil) as? NSTableCellView {
                view.textField?.bind(.value, to: track, withKeyPath: \.rTitle)
                return view
            }
        }
        else if tableColumn?.identifier == ColumnIdentifiers.author, let view = tableView.makeView(withIdentifier: CellIdentifiers.author, owner: nil) as? NSTableCellView {
            view.textField?.bind(.value, to: track, withKeyPath: \.author)
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.album, let view = tableView.makeView(withIdentifier: CellIdentifiers.album, owner: nil) as? NSTableCellView {
            view.textField?.bind(.value, to: track, withKeyPath: \.album)
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.genre, let view = tableView.makeView(withIdentifier: CellIdentifiers.genre, owner: nil) as? NSTableCellView {
            view.textField?.bind(.value, to: track, withKeyPath: \.genre)
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.bpm, let view = tableView.makeView(withIdentifier: CellIdentifiers.bpm, owner: nil) as? NSTableCellView {
            view.textField?.bind(.value, to: track, withKeyPath: \.speed) { $0.map {
                NSAttributedString(string: $0.description, attributes: $0.attributes).with(alignment: .center)
                } }
            
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.key, let view = tableView.makeView(withIdentifier: CellIdentifiers.key, owner: nil) as? NSTableCellView {
            view.textField?.bind(.value, to: track, withKeyPath: \.key) { $0.map {
                NSAttributedString(string: $0.description, attributes: $0.attributes).with(alignment: .center)
                } }
            
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.duration, let view = tableView.makeView(withIdentifier: CellIdentifiers.duration, owner: nil) as? NSTableCellView {
            view.textField?.bind(.value, to: track, withKeyPath: \.rDuration)
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.dateAdded, let view = tableView.makeView(withIdentifier: CellIdentifiers.dateAdded, owner: nil) as? NSTableCellView {
            view.textField?.bind(.value, to: track, withKeyPath: \.rCreationDate)
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.year, let view = tableView.makeView(withIdentifier: CellIdentifiers.year, owner: nil) as? NSTableCellView {
            view.textField?.bind(.value, to: track, withKeyPath: \.year) {
                ($0 == 0 ? nil : String($0)) as NSString?
            }
            return view
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        if let track = history.track(at: row) {
            let exists = track.liveURL != nil
            if !exists {
                rowView.backgroundColor = NSColor(red: 0.1, green: 0.05, blue: 0.05, alpha: 1)
            }
        }
        
        rowView.layer?.sublayers = []
        rowView.wantsLayer = false
        if history.playingIndex == row {
            rowView.wantsLayer = true
            rowView.layer?.addBorder(edge: .minY, color: .gray, thickness: 2)
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if mode == .queue {
            return history.playingIndex == row ? tableView.rowHeight + 2 : tableView.rowHeight
        }
        else if mode == .tracksList {
            return AppDelegate.defaults.trackSmallRows && !AppDelegate.defaults.trackCombinedTitleSource ? TrackController.smallRowHeight : tableView.rowHeight
        }
        
        return tableView.rowHeight
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return SubtleTableRowView()
    }
    
    @IBAction func showInfo(_ sender: Any?) {
        (trackEditorGuard.superview as! NSSplitView).toggleSubviewHidden(trackEditorGuard)
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return mode != .title
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let indices = Array(_tableView.selectedRowIndexes)
        let tracks = indices.map { history.track(at: $0)! }
        
        guard !tracks.isEmpty && trackEditor.tracks.noneSatisfy({ $0.isDeleted }) else {
            // Honestly, if the selection is set to void but the tracks are all still THERE
            // Then why change the view? This is especially useful if we edit a track inside a smart playlist
            
            return
        }
        
        trackEditorGuard.present(elements: tracks)
    }
}

extension TrackController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return history.count
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        if let sortDescriptor = tableView.sortDescriptors.onlyElement, sortDescriptor.key == oldDescriptors.onlyElement?.key, sortDescriptor.ascending {
            // clicked third time, unsort nao
            desired.sort = nil
            tableView.sortDescriptors = []
            
            return
        }
        
        if let descriptor = tableView.sortDescriptors.onlyElement, let key = descriptor.key, key != "none" {
            switch key {
            case "title":
                desired.sort = { $0.rTitle < $1.rTitle }
            case "author":
                desired.sort = { $0.author ?? "" < $1.author ?? "" }
            case "album":
                desired.sort = { $0.album ?? "" < $1.album ?? "" }
            case "genre":
                desired.sort = { Optional<String>.compare($0.genre, $1.genre) }
            case "key":
                desired.sort = { Optional<Key>.compare($0.key, $1.key) }
            case "bpm":
                desired.sort = { ($0.speed ?? Track.Speed.zero) < ($1.speed ?? Track.Speed.zero)  }
            case "duration":
                desired.sort = { ($0.duration ?? kCMTimeZero) < ($1.duration ?? kCMTimeZero)  }
            case "dateAdded":
                desired.sort = { $0.creationDate.timeIntervalSinceReferenceDate < $1.creationDate.timeIntervalSinceReferenceDate }
            case "year":
                desired.sort = { $0.year < $1.year }
            default:
                fatalError("Unknown Sort Descriptor Key")
            }
            
            // Hax
            if !descriptor.ascending {
                let sorter = desired.sort!
                desired.sort = { !sorter($0, $1) }
            }
        }
        else {
            desired.sort = nil
            tableView.sortDescriptors = [] // Update the view so it doesn't show an arrow on the affected columns
        }
        
        desired._changed = true
    }
}
