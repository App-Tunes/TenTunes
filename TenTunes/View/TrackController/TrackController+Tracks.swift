//
//  TrackController+Tracks.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 01.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation
import TunesUI

extension TrackController {
    var selectedTrack: Track? {
        let row = self._tableView.selectedRow
        return row >= 0 ? history.track(at: row) : nil
    }
    
    func initTable() {
        _tableView.enterAction = #selector(enterAction(_:))
        _tableView.registerForDraggedTypes(pasteboardTypes)
        _tableView.setDraggingSourceOperationMask(.every, forLocal: false) // ESSENTIAL
        
        tableViewHiddenExtension = .init(tableView: _tableView, titles: [
            ColumnIdentifiers.artwork: "Artwork (⸬)",
            ColumnIdentifiers.waveform: "Waveform (⏦)",
            ColumnIdentifiers.bpm: "Beats per Minute (♩=)",
            ColumnIdentifiers.key: "Initial Key (♫)",
            ColumnIdentifiers.duration: "Duration (◷)",
        ], affix: [ColumnIdentifiers.title.rawValue])
        tableViewHiddenExtension.attach()
        
        tableViewSynchronizer = .init(tableView: _tableView)
        tableViewSynchronizer.attach()
    }
    
    func reloadGUI() {
        _playlistTitle.stringValue = history.playlist.name
        _playlistIcon.image = history.playlist.icon
        _trackCounter.stringValue = String(describe: history.count,
                                           singular: AppDelegate.defaults[.trackWordSingular],
                                           plural: AppDelegate.defaults[.trackWordPlural])
        
        dragHighlightView.isHidden = !acceptsGeneralDrag
        
        // Resize album column to always be of equal width and height
        // Height of row only changes when history changes right now
        let albumColumn = _tableView.tableColumns[_tableView.column(withIdentifier: ColumnIdentifiers.artwork)]
        albumColumn.width = tableView(_tableView, heightOfRow: 0)
                
        guard mode == .tracksList else {
            return
        }
        
        if let playlist = history.playlist as? PlaylistSmart {
            _ruleButton.isHidden = false
            if smartPlaylistRuleController.rules != playlist.rrules {
                smartPlaylistRuleController.rules = playlist.rrules
            }
            ruleBar.contentView = smartPlaylistRuleController.view
            
            smartPlaylistRuleController._tokenField.isEditable = !playlist.parent!.automatesChildren
            if smartPlaylistRuleController.tokens.isEmpty { ruleBar.open() }
        }
        else if let playlist = history.playlist as? PlaylistCartesian {
            _ruleButton.isHidden = false
            if smartFolderRuleController.tokens != playlist.rules.tokens {
                smartFolderRuleController.tokens = playlist.rules.tokens
            }
            ruleBar.contentView = smartFolderRuleController.view
            
            smartFolderRuleController._tokenField.isEditable = !playlist.parent!.automatesChildren
            if smartFolderRuleController.tokens.isEmpty { ruleBar.open() }
        }
        else {
            _ruleButton.isHidden = true
            ruleBar.close()
        }

    }
    
    func play(atRow row: Int) {
        TrackActions.create(.playlist(at: [row], in: history))?.menuPlay(self)
    }
    
    @IBAction func enterAction(_ sender: Any) {
        play(atRow: self._tableView.selectedRow)
    }
    
    @IBAction func doubleClick(_ sender: Any) {
        play(atRow: _tableView.clickedRow)
    }
    
    func reload(track: Track) {
        if let row = history.indexOf(track: track) {
            // TODO Remove all
            _tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: [1])
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
        
        play(atRow: row)
    }

    func select(tracks: [Track]) {
        // First selection, for most cases this is enough, but there's no better way anyway
        let indices = tracks.compactMap(history.indexOf)
        
        if let first = indices.first { _tableView.scrollRowToVisible(first) }
        // didSelect will be called automatically by delegate method
        _tableView.selectRowIndexes(IndexSet(indices), byExtendingSelection: false)
    }
}

func makeRoundRect(view: NSView) {
    view.wantsLayer = true
    view.layer!.borderWidth = 1.0
    view.layer!.borderColor = NSColor.lightGray.cgColor.copy(alpha: CGFloat(0.333))
    view.layer!.cornerRadius = 3.0
    view.layer!.masksToBounds = true
}

extension TrackController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let track = history.track(at: row)!
        
        if tableColumn?.identifier == ColumnIdentifiers.artwork, let view = tableView.makeView(withIdentifier: mode != .title ? CellIdentifiers.artwork : CellIdentifiers.staticArtwork, owner: nil) {
            
            StylerMyler.makeRoundRect(view)
            
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
        else if tableColumn?.identifier == ColumnIdentifiers.waveform, let view = tableView.makeView(withIdentifier: CellIdentifiers.waveform, owner: nil) as? WaveformPositionCocoa {
            if track.analysis == nil {
                track.readAnalysis()
            }
            
			if view.waveformView.resample == nil {
				// New instance
				view.waveformView.resample = ResampleToSize.bestOrZero
				view.waveformView.colorLUT = Gradients.pitchCG
				
				view.positionControl.useJumpInterval = {
					!NSEvent.modifierFlags.contains(.option)
				}
			}

			view.waveformView.reset(suppressAnimationsUntil: Date() + 0.5)
			view.waveformView.waveform = .from(track.analysis?.values)

			let player = ViewController.shared.player
			view.positionControl.action = { [weak self] in
				self?.play(atRow: row)
				
				switch $0 {
				case .absolute(let position):
					player.setPosition(Double(position), smooth: false)
				case .relative(let movement):
					player.movePosition(Double(movement), smooth: false)
				}
			}
			
			if let duration = track.duration {
				view.positionControl.locationProvider = {
					player.playing == track ? player.currentTime.map { CGFloat($0) } : nil
				}
				view.positionControl.timer.fps = 10  // TODO only when active
				view.positionControl.range = 0...CGFloat(duration.seconds)
				
				view.positionControl.jumpInterval = track.speed.map {
					CGFloat($0.secondsPerBeat * 16)
				} ?? nil
			}
			else {
				view.positionControl.locationProvider = { nil }
				view.positionControl.timer.fps = 0
				view.positionControl.range = 0...1
			}
            
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.title {
            if AppDelegate.defaults[.trackCombinedTitleSource], let view = tableView.makeView(withIdentifier: CellIdentifiers.combinedTitle, owner: nil) as? TitleSubtitleCellView {
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
            view.textField?.bind(.value, to: track, withKeyPath: \.keyString) {
                $0.map {
                    if let key = Key.parse($0) {
                        let string = AppDelegate.defaults[.initialKeyDisplay] == .file ? $0 : key.description
                        
                        return NSAttributedString(string: string, attributes: key.attributes).with(alignment: .center)
                    }
                    else {
                        return NSAttributedString(string: $0)
                    }
                }
            }
            
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
        else if tableColumn?.identifier == ColumnIdentifiers.playCount, let view = tableView.makeView(withIdentifier: CellIdentifiers.playCount, owner: nil) as? NSTableCellView {
            view.textField?.bind(.value, to: track, withKeyPath: \.playCount) {
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
            return AppDelegate.defaults[.trackSmallRows] && !AppDelegate.defaults[.trackCombinedTitleSource] ? TrackController.smallRowHeight : tableView.rowHeight
        }
        
        return tableView.rowHeight
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return SubtleTableRowView()
    }
    
    @IBAction func showInfo(_ sender: Any?) {
        let split = trackEditorGuard.superview as! NSSplitView
            
        split.toggleSubviewHidden(trackEditorGuard)
        
        if !trackEditorGuard.isHidden {
            split.layout()
            split.adaptSubview(trackEditorGuard, toMinSize: 250, from: .left)
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return mode != .title
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let indices = Array(_tableView.selectedRowIndexes)
        let tracks = indices.map { history.track(at: $0)! }
        
        guard !tracks.isEmpty && tracks.noneSatisfy({ $0.wasDeleted }) else {
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
        if let sortDescriptor = tableView.sortDescriptors.first, sortDescriptor.key == oldDescriptors.first?.key, !sortDescriptor.ascending {
            // clicked third time, unsort nao
            desired.sort = nil
            tableView.sortDescriptors = []
            
            return
        }
        
        // TODO Other descriptors, ignore?
        if let descriptor = tableView.sortDescriptors.first, let key = descriptor.key, key != "none" {
            switch key {
            case "title":
                desired.sort = { $1.rTitle < $0.rTitle }
            case "author":
                desired.sort = { $1.author ?? "" < $0.author ?? "" }
            case "album":
                desired.sort = { $1.album ?? "" < $0.album ?? "" }
            case "genre":
                desired.sort = { Optional<String>.compare($1.genre, $0.genre) }
            case "key":
                desired.sort = { Optional<Key>.compare($1.key, $0.key) }
            case "bpm":
                desired.sort = { ($0.speed ?? Track.Speed.zero) < ($1.speed ?? Track.Speed.zero)  }
            case "duration":
                desired.sort = { ($0.duration ?? CMTime.zero) < ($1.duration ?? CMTime.zero)  }
            case "dateAdded":
                desired.sort = { $0.creationDate.timeIntervalSinceReferenceDate < $1.creationDate.timeIntervalSinceReferenceDate }
            case "year":
                desired.sort = { $0.year < $1.year }
            case "playCount":
                desired.sort = { $0.playCount < $1.playCount }
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
