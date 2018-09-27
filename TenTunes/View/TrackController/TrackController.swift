//
//  TrackController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation

@objc class PlayHistorySetup : NSObject {
    var completion: (PlayHistory) -> Swift.Void
    
    init(completion: @escaping (PlayHistory) -> Swift.Void) {
        self.completion = completion
    }
    
    var _changed = false {
        didSet { isDone = isDone && !_changed }
    }
    @objc dynamic var isDone = true

    var playlist: PlaylistProtocol? {
        didSet { if oldValue !== playlist { _changed = true }}
    }

    var filter: ((Track) -> Bool)? {
        didSet { _changed = true }
    }
    
    var sort: ((Track, Track) -> Bool)? {
        didSet { _changed = true }
    }
}

class TrackController: NSViewController {
    @IBOutlet var _tableView: ActionTableView!
    @IBOutlet var _tableViewHeight: NSLayoutConstraint!
    
    @IBOutlet var _trackEditorView: NSView!
    
    @IBOutlet var filterController: SmartPlaylistRulesController!
    @IBOutlet var filterBar: HideableBar!
    @IBOutlet var _filterBarContainer: NSView!

    @IBOutlet var smartPlaylistRuleController: SmartPlaylistRulesController!
    @IBOutlet var smartFolderRuleController: CartesianRulesController!
    @IBOutlet var ruleBar: HideableBar!
    @IBOutlet var _ruleBarContainer: NSView!
    @IBOutlet var _ruleButton: NSButton!
    
    @IBOutlet var _playlistTitle: NSTextField!
    @IBOutlet var _playlistInfoBarHeight: NSLayoutConstraint!
    
    var trackEditor : TrackEditor!
    @IBOutlet var trackEditorGuard : MultiplicityGuardView!

    var playTrack: ((Int, Double?) -> Swift.Void)?
    var playTrackNext: ((Int) -> Swift.Void)?

    var history: PlayHistory = PlayHistory(playlist: PlaylistEmpty()) {
        didSet {
            _tableView?.animateDifference(from: oldValue.tracks, to: history.tracks)
            
            _playlistTitle.stringValue = history.playlist.name
            _trackCounter.stringValue = String(history.count) + (history.count != 1 ? " tracks" : " track")
            
            guard mode == .tracksList else {
                return
            }
            
            if let playlist = history.playlist as? PlaylistSmart {
                _ruleButton.isHidden = false
                if smartPlaylistRuleController.rules != playlist.rrules {
                    smartPlaylistRuleController.rules = playlist.rrules
                }
                ruleBar.contentView = smartPlaylistRuleController.view
            }
            else if let playlist = history.playlist as? PlaylistCartesian {
                _ruleButton.isHidden = false
                if smartFolderRuleController.tokens != playlist.rules.tokens {
                    smartFolderRuleController.tokens = playlist.rules.tokens
                }
                ruleBar.contentView = smartFolderRuleController.view
            }
            else {
                _ruleButton.isHidden = true
                ruleBar.close()
            }
        }
    }
    @objc dynamic var desired: PlayHistorySetup!
    @IBOutlet var _loadingIndicator: NSProgressIndicator!

    var mode: Mode = .tracksList

    var isDark: Bool {
        return self.view.window!.appearance?.name == NSAppearance.Name.vibrantDark
    }
    
    @IBOutlet var _moveToMediaDirectory: NSMenuItem!
    @IBOutlet var _analyzeSubmenu: NSMenuItem!
    @IBOutlet var _showInPlaylistSubmenu: NSMenuItem!

    @IBOutlet var _trackCounter: NSTextField!
    
    var observeHiddenToken: NSKeyValueObservation?
    
    enum Mode {
        case tracksList, queue, title
    }

    override func awakeFromNib() {
        desired = PlayHistorySetup { self.history = $0 }
        
        observeHiddenToken = desired.observe(\.isDone, options: [.new, .initial]) { [unowned self] object, change in
            guard self.mode != .title else {
                return
            }
            
            let isDone = change.newValue!
            
            if !isDone { self._loadingIndicator.startAnimation(self) }

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                self._loadingIndicator.animator().alphaValue = isDone ? 0 : 1
            }) {
                if isDone && self.desired.isDone { self._loadingIndicator.stopAnimation(self) }
            }
        }

        trackEditor = TrackEditor()
        
        trackEditorGuard.delegate = self
        trackEditorGuard.bigSelectionCount = 5
        trackEditorGuard.errorSelectionEmpty = "No Tracks Selected"
        trackEditorGuard.warnSelectionBig = "Many Tracks Selected"
        trackEditorGuard.confirmShowView = "Edit Anyway"
        trackEditorGuard.contentView = trackEditor.view
        trackEditorGuard.present(elements: [])

        _tableView.enterAction = #selector(enterAction(_:))
        _tableView.registerForDraggedTypes(pasteboardTypes)
        _tableView.setDraggingSourceOperationMask(.every, forLocal: false) // ESSENTIAL
        
        _playlistTitle.stringValue = ""
        
        filterBar = HideableBar(nibName: .init(rawValue: "HideableBar"), bundle: nil)
        filterBar.height = 32
        filterBar.delegate = self
        _filterBarContainer.setFullSizeContent(filterBar.view)
        
        filterController = SmartPlaylistRulesController(nibName: .init(rawValue: "SmartPlaylistRulesController"), bundle: nil)
        filterController.delegate = self
        filterBar.contentView = filterController.view

        ruleBar = HideableBar(nibName: .init(rawValue: "HideableBar"), bundle: nil)
        ruleBar.height = 32
        ruleBar.delegate = self
        _ruleBarContainer.setFullSizeContent(ruleBar.view)

        smartPlaylistRuleController = SmartPlaylistRulesController(nibName: .init(rawValue: "SmartPlaylistRulesController"), bundle: nil)
        smartPlaylistRuleController.delegate = self
        ruleBar.contentView = smartPlaylistRuleController.view
        
        smartFolderRuleController = CartesianRulesController(nibName: .init(rawValue: "CartesianRulesController"), bundle: nil)
        smartFolderRuleController.delegate = self
        smartFolderRuleController.loadView()
    }
    
    override func viewDidAppear() {
        _tableView.backgroundColor = NSColor.clear

        // Appearance is not yet set in willappear
        if mode == .tracksList {
            _tableView.enclosingScrollView?.backgroundColor = isDark ? NSColor(white: 0.09, alpha: 1.0) : NSColor(white: 0.73, alpha: 1.0)
            // A little hacky but eh
            for visual in _tableView.headerView?.superview?.subviews.flatten(by: { $0.subviews }).of(type: NSVisualEffectView.self) ?? [] {
                if #available(OSX 10.14, *) {
                    visual.material = .underWindowBackground
                }
            }
        }
    }
        
    func queueify() {
        mode = .queue
        
        _tableView.headerView = nil
        _tableView.enclosingScrollView?.drawsBackground = false
        _tableView.enclosingScrollView?.backgroundColor = NSColor.clear
        _tableView.usesAlternatingRowBackgroundColors = false  // TODO In NSPanels, this is solid while everything else isn't
        trackEditorGuard.removeFromSuperview()
        
        playTrackNext = { [unowned self] in
            let tracksBefore = self.history.tracks
            self.history.insert(tracks: [self.history.track(at: $0)!], before: self.history.playingIndex + 1)
            self._tableView.animateDifference(from: tracksBefore, to: self.history.tracks)
        }
        
         // Unintuitive to use in a queue
        // TODO Make non-interactable?
        _tableView.tableColumn(withIdentifier: ColumnIdentifiers.waveform)?.isHidden = true
        
        // We believe in tags, not genres
        _tableView.tableColumn(withIdentifier: ColumnIdentifiers.genre)?.isHidden = true
    }
    
    func titleify() {
        queueify()
        mode = .title
                
        _playlistInfoBarHeight.constant = 0
        _tableViewHeight.constant = 0
        _tableView.enclosingScrollView?.hasVerticalScroller = false
        _tableView.enclosingScrollView?.hasHorizontalScroller = false
        _tableView.enclosingScrollView?.verticalScrollElasticity = .none
        _tableView.enclosingScrollView?.horizontalScrollElasticity = .none
    }
    
    var visibleTracks: [Track] {
        var tracks: [Track] = []
        
        if let visibleRect = self._tableView.enclosingScrollView?.contentView.visibleRect {
            let visibleRows = self._tableView.rows(in: visibleRect)
            
            for row in visibleRows.lowerBound...visibleRows.upperBound {
                if let track = history.track(at: row) {
                    tracks.append(track)
                }
            }
        }
        
        return tracks
    }
    
    var selectedTrack: Track? {
        let row = self._tableView.selectedRow
        return row >= 0 ? history.track(at: row) : nil
    }
    
    func playCurrentTrack() {
        if selectedTrack != nil, let playTrack = playTrack {
            playTrack(self._tableView.selectedRow, nil)
        }
    }
    
    @IBAction func enterAction(_ sender: Any) {
        playCurrentTrack()
    }
    
    @IBAction func doubleClick(_ sender: Any) {
        let row = _tableView.clickedRow
        
        if let playTrack = playTrack {
            if history.track(at: row) != nil {
                playTrack(row, nil)
            }
        }
    }
    
    func reload(track: Track) {
        if let row = history.indexOf(track: track) {
            _tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(0..<_tableView.numberOfColumns))
        }
    }
    
    @IBAction func waveformViewClicked(_ sender: Any?) {
        if let view = sender as? WaveformView {
            if let row = view.superview ?=> _tableView.row, history.track(at: row) != nil, let playTrack = playTrack {
                playTrack(row, view.location)
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
}

extension TrackController: NSTableViewDelegate {
    fileprivate enum CellIdentifiers {
        static let artwork = NSUserInterfaceItemIdentifier(rawValue: "artworkCell")
        static let waveform = NSUserInterfaceItemIdentifier(rawValue: "waveformCell")
        static let title = NSUserInterfaceItemIdentifier(rawValue: "titleCell")
        static let genre = NSUserInterfaceItemIdentifier(rawValue: "genreCell")
        static let bpm = NSUserInterfaceItemIdentifier(rawValue: "bpmCell")
        static let key = NSUserInterfaceItemIdentifier(rawValue: "keyCell")
        static let duration = NSUserInterfaceItemIdentifier(rawValue: "durationCell")
    }
    
    fileprivate enum ColumnIdentifiers {
        static let artwork = NSUserInterfaceItemIdentifier(rawValue: "artworkColumn")
        static let waveform = NSUserInterfaceItemIdentifier(rawValue: "waveformColumn")
        static let title = NSUserInterfaceItemIdentifier(rawValue: "titleColumn")
        static let genre = NSUserInterfaceItemIdentifier(rawValue: "genreColumn")
        static let bpm = NSUserInterfaceItemIdentifier(rawValue: "bpmColumn")
        static let key = NSUserInterfaceItemIdentifier(rawValue: "keyColumn")
        static let duration = NSUserInterfaceItemIdentifier(rawValue: "durationColumn")
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let track = history.track(at: row)!
        
        if tableColumn?.identifier == ColumnIdentifiers.artwork, let view = tableView.makeView(withIdentifier: CellIdentifiers.artwork, owner: nil) as? NSImageView {
            view.wantsLayer = true
            
            view.layer!.borderWidth = 1.0
            view.layer!.borderColor = NSColor.lightGray.cgColor.copy(alpha: CGFloat(0.333))
            view.layer!.cornerRadius = 3.0
            view.layer!.masksToBounds = true

            view.image = track.artworkPreview ?? Album.missingArtwork

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
                        
            // For the small previews, less fps is enough (for performance)
            view.updateTime = 1 / 10
            view.completeTransitionSteps = 10

            view.setInstantly(analysis: track.analysis)
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.title, let view = tableView.makeView(withIdentifier: CellIdentifiers.title, owner: nil) as? TitleSubtitleCellView {
            view.textField?.stringValue = track.rTitle
            view.subtitleTextField?.stringValue = track.rSource
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.genre, let view = tableView.makeView(withIdentifier: CellIdentifiers.genre, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = track.genre ?? ""
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.bpm, let view = tableView.makeView(withIdentifier: CellIdentifiers.bpm, owner: nil) as? NSTableCellView {
            view.textField?.attributedStringValue = track.speed?.attributedDescription.with(alignment: .right) ?? NSAttributedString()
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.key, let view = tableView.makeView(withIdentifier: CellIdentifiers.key, owner: nil) as? NSTableCellView {
            view.textField?.attributedStringValue = track.key?.description ?? NSAttributedString()
            view.textField?.setAlignment(.center) // Is reset when setting attributed string
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.duration, let view = tableView.makeView(withIdentifier: CellIdentifiers.duration, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = track.rDuration 
            return view
        }

        return nil
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        if let track = history.track(at: row) {
            let exists = track.url != nil
            if !exists {
                rowView.backgroundColor = NSColor(red: 0.1, green: 0.05, blue: 0.05, alpha: 1)
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return VibrantTableRowView()
    }
    
    @IBAction func showInfo(_ sender: Any?) {
        (trackEditorGuard.superview as! NSSplitView).toggleSubviewHidden(trackEditorGuard)
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        // TODO We only care about the first
        if let descriptor = tableView.sortDescriptors.first, let key = descriptor.key, key != "none" {
            switch key {
            case "title":
                desired.sort = { $0.rTitle < $1.rTitle }
            case "genre":
                desired.sort = { Optional<String>.compare($0.genre, $1.genre) }
            case "key":
                desired.sort = { Optional<Key>.compare($0.key, $1.key) }
            case "bpm":
                desired.sort = { ($0.speed ?? Track.Speed.zero) < ($1.speed ?? Track.Speed.zero)  }
            case "duration":
                desired.sort = { ($0.duration ?? kCMTimeZero) < ($1.duration ?? kCMTimeZero)  }
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
}

extension TrackController : HideableBarDelegate {
    func hideableBar(_ bar: HideableBar, didChangeState state: Bool) {
        if bar == ruleBar {
            _ruleButton.state = state ? .on : .off
            
            if state == false {
                smartPlaylistRuleController._tokenField.resignFirstResponder()
            }
        }
        else if bar == filterBar {
            if state == false {
                desired.filter = nil
                filterController._tokenField.resignFirstResponder()
            }
        }
        
        view.window?.makeFirstResponder(view)
    }
}

extension TrackController : MultiplicityGuardDelegate {
    func multiplicityGuard(_ view: MultiplicityGuardView, show elements: [Any]) -> MultiplicityGuardView.ShowAction {
        let tracks = elements as! [Track]
        guard tracks.allSatisfy({ $0.url != nil }) else {
            return .error(text: "Track Not Found")
        }
        
        trackEditor!.show(tracks: tracks)
        return .show
    }
}

extension TrackController : NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return subview == trackEditor.view
    }
}
