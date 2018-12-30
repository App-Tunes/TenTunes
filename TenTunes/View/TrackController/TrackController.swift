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
    override init() {
    }
    
    var _changed = false {
        didSet { isDone = isDone && !_changed }
    }
    @objc dynamic var isDone = true

    var playlist: PlaylistProtocol? {
        didSet { _changed = _changed || oldValue !== playlist }
    }

    var filter: ((Track) -> Bool)? {
        didSet { _changed = _changed || oldValue != nil || filter != nil }
    }
    
    var sort: ((Track, Track) -> Bool)? {
        didSet { _changed = _changed || oldValue != nil || sort != nil }
    }
}

class TrackController: NSViewController {
    @IBOutlet var _tableView: ActionTableView!
    @IBOutlet var _tableViewHeight: NSLayoutConstraint!
    var tableViewHiddenManager: NSTableView.HiddenManager!
    
    @IBOutlet var filterController: SmartPlaylistRulesController!
    @IBOutlet var filterBar: HideableBar!
    @IBOutlet var _filterBarContainer: NSView!

    @IBOutlet var smartPlaylistRuleController: SmartPlaylistRulesController!
    @IBOutlet var smartFolderRuleController: CartesianRulesController!
    @IBOutlet var ruleBar: HideableBar!
    @IBOutlet var _ruleBarContainer: NSView!
    @IBOutlet var _ruleButton: NSButton!
    
    @IBOutlet var _playlistTitle: NSTextField!
    @IBOutlet var _playlistIcon: NSImageView!
    @IBOutlet var _playlistInfoBarHeight: NSLayoutConstraint!
    
    var dragHighlightView: DragHighlightView!
    
    var trackEditor : TrackEditor!
    @IBOutlet var trackEditorGuard : MultiplicityGuardView!

    var playTrack: ((Int, Double?) -> Swift.Void)?
    var playTrackNext: ((Int) -> Swift.Void)?
    var playTrackLater: ((Int) -> Swift.Void)?

    var history: PlayHistory = PlayHistory(playlist: PlaylistEmpty()) {
        didSet {
            _tableView?.animateDifference(from: oldValue.tracks, to: history.tracks)
            
            _playlistTitle.stringValue = history.playlist.name
            _playlistIcon.image = history.playlist.icon
            _trackCounter.stringValue = String(history.count) + (history.count != 1 ? " tracks" : " track")
            
            dragHighlightView.isHidden = !acceptsGeneralDrag
            
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
            }
            else if let playlist = history.playlist as? PlaylistCartesian {
                _ruleButton.isHidden = false
                if smartFolderRuleController.tokens != playlist.rules.tokens {
                    smartFolderRuleController.tokens = playlist.rules.tokens
                }
                ruleBar.contentView = smartFolderRuleController.view
                
                smartFolderRuleController._tokenField.isEditable = !playlist.parent!.automatesChildren
            }
            else {
                _ruleButton.isHidden = true
                ruleBar.close()
            }
        }
    }
    @objc dynamic var desired: PlayHistorySetup = PlayHistorySetup()
    @IBOutlet var _loadingIndicator: NSProgressIndicator!

    var mode: Mode = .tracksList

    var isDark: Bool {
        return self.view.window!.appearance?.name == NSAppearance.Name.vibrantDark
    }
    
    @IBOutlet var _moveToMediaDirectory: NSMenuItem!
    @IBOutlet var _analyzeSubmenu: NSMenuItem!
    @IBOutlet var _showInPlaylistSubmenu: NSMenuItem!
    @IBOutlet var _addToPlaylistSubmenu: NSMenuItem!
    
    @IBOutlet var _trackCounter: NSTextField!
    
    var observeHiddenToken: NSKeyValueObservation?
    
    enum Mode {
        case tracksList, queue, title
    }

    override func awakeFromNib() {
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

        dragHighlightView = DragHighlightView.add(to: _loadingIndicator.superview!)
        dragHighlightView.registerForDraggedTypes(TrackPromise.pasteboardTypes)
        dragHighlightView.delegate = self
        
        tableViewHiddenManager = .init(tableView: _tableView, defaultsKey: "trackColumnsHidden", ignore: [ColumnIdentifiers.title.rawValue, ColumnIdentifiers.artwork.rawValue])
        tableViewHiddenManager.start()
        
        registerObservers()
    }
    
    override func viewDidAppear() {
        _tableView.backgroundColor = NSColor.clear

        // Appearance is not yet set in willappear
        if mode == .tracksList {
            _tableView.enclosingScrollView?.backgroundColor = isDark ? NSColor(white: 0.09, alpha: 1.0) : NSColor(white: 0.73, alpha: 1.0)
            
            if #available(OSX 10.14, *) {
                _tableView.headerView?.vibrancyView?.material = .underWindowBackground
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
        
        self._loadingIndicator.isHidden = true
        observeHiddenToken = nil // We don't want loading animations round here
        
        playTrackNext = { [unowned self] in
            let tracksBefore = self.history.tracks
            self.history.enqueue(tracks: [self.history.track(at: $0)!], at: .start)
            self._tableView.animateDifference(from: tracksBefore, to: self.history.tracks)
        }
        
        playTrackLater = { [unowned self] in
            let tracksBefore = self.history.tracks
            self.history.enqueue(tracks: [self.history.track(at: $0)!], at: .end)
            self._tableView.animateDifference(from: tracksBefore, to: self.history.tracks)
        }
        
        for column in _tableView.tableColumns {
            switch column.identifier {
            case ColumnIdentifiers.artwork, ColumnIdentifiers.title, ColumnIdentifiers.key, ColumnIdentifiers.bpm, ColumnIdentifiers.duration, ColumnIdentifiers.author:
                continue
            default:
                // Unintuitive to use in a queue
                column.isHidden = true
                tableViewHiddenManager.ignore.append(column.identifier.rawValue)
            }
        }
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
    fileprivate enum CellIdentifiers {
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
    
    fileprivate enum ColumnIdentifiers {
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
                        
            // For the small previews, less fps is enough (for performance)
            view.updateTime = 1 / 10
            view.completeTransitionSteps = 10
            view.duration = track.duration?.seconds ?? 1

            view.setInstantly(analysis: track.analysis)
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.title {
            if UserDefaults.standard.trackCombinedTitleSource, let view = tableView.makeView(withIdentifier: CellIdentifiers.combinedTitle, owner: nil) as? TitleSubtitleCellView {
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
            return UserDefaults.standard.trackSmallRows && !UserDefaults.standard.trackCombinedTitleSource ? 20 : tableView.rowHeight
        }
        
        return tableView.rowHeight
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return SubtleTableRowView()
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
        }
        else if bar == filterBar {
            desired.filter = state ? filterController.rules.filter(in: Library.shared.viewContext) : nil
            
            // TODO Too omniscient, let ViewController observe it itself
            ViewController.shared._find.state = state ? .on : .off
        }
        
        if view.window?.firstResponder == nil {
            // It was probably the bar, but who cares, it's freeee
            view.window?.makeFirstResponder(_tableView)
        }
    }
}

extension TrackController : MultiplicityGuardDelegate {
    func multiplicityGuard(_ view: MultiplicityGuardView, show elements: [Any]) -> MultiplicityGuardView.ShowAction {
        let tracks = elements as! [Track]
        guard tracks.allSatisfy({ $0.liveURL != nil }) else {
            return .error(text: "Track Not Found")
        }
        
        trackEditor!.show(tracks: tracks)
        return .show
    }
}

extension TrackController : NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return subview == trackEditorGuard
    }
}
