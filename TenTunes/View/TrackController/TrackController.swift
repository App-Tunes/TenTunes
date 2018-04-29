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
    
    var semaphore = DispatchSemaphore(value: 1)
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
    @IBOutlet var _tableView: NSTableView!
    
    @IBOutlet weak var _searchField: NSSearchField!
    @IBOutlet var _searchBarHeight: NSLayoutConstraint!
    @IBOutlet weak var _searchBarClose: NSButton!
    
    @IBOutlet var _playlistTitle: NSTextField!
    
    var infoEditor : FileTagEditor!
    
    @IBOutlet weak var _sortLabel: NSTextField!
    @IBOutlet weak var _sortBar: NSView!
    
    var playTrack: ((Int, Double?) -> Swift.Void)?
    var playTrackNext: ((Int) -> Swift.Void)?

    var history: PlayHistory = PlayHistory(playlist: PlaylistEmpty()) {
        didSet {
            _tableView?.animateDifference(from: oldValue.tracks, to: history.tracks)
            _playlistTitle.stringValue = history.playlist.name
        }
    }
    @objc dynamic var desired: PlayHistorySetup!
    @IBOutlet var _loadingIndicator: NSProgressIndicator!

    var isQueue = false

    var isDark: Bool {
        return self.view.window!.appearance?.name == NSAppearance.Name.vibrantDark
    }
    
    @IBOutlet var _moveToMediaDirectory: NSMenuItem!
    @IBOutlet var _analyzeSubmenu: NSMenuItem!
    @IBOutlet var _showInPlaylistSubmenu: NSMenuItem!

    var observeHiddenToken: NSKeyValueObservation?

    override func awakeFromNib() {
        desired = PlayHistorySetup { self.history = $0 }
        _loadingIndicator.startAnimation(self)
        _loadingIndicator.alphaValue = 0 // By default, nothing is to be loaded
        
        observeHiddenToken = desired.observe(\.isDone, options: [.new]) { [weak self] object, change in
            let isDone = change.newValue!
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                self?._loadingIndicator.animator().alphaValue = isDone ? 0 : 1
            }, completionHandler: nil)
        }

        infoEditor = FileTagEditor()
        
        _tableView.registerForDraggedTypes([Track.pasteboardType])
        _tableView.setDraggingSourceOperationMask(.every, forLocal: false) // ESSENTIAL
        
        _searchBarHeight.constant = CGFloat(0)
        
        _playlistTitle.stringValue = ""
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.keyDown(with: $0)
        }
    }
    
    override func viewDidAppear() {
        // Appearance is not yet set in willappear
        if !isQueue {
            _tableView.backgroundColor = isDark ? NSColor(white: 0.09, alpha: 1.0) : NSColor(white: 0.73, alpha: 1.0)
        }
    
        // Hide border by painting it in the background color
        // TODO Match window bg color exactly - it returns white by default...
        if let header = _tableView.headerView {
            header.wantsLayer = true
            header.layer!.borderColor = (isDark ? NSColor(white: 0.12, alpha: 1.0) : NSColor(white: 1, alpha: 1.0)).cgColor
            header.layer!.borderWidth = 1
        }
        
        infoEditor.window?.appearance = view.window!.appearance
    }
        
    func queueify() {
        isQueue = true
        
        _tableView.headerView = nil
        _tableView.usesAlternatingRowBackgroundColors = false  // TODO In NSPanels, this is solid while everything else isn't
        
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
    
    @IBAction func doubleClick(_ sender: Any) {
        let row = self._tableView.clickedRow
        
        if let playTrack = playTrack {
            if history.track(at: row) != nil {
                playTrack(row, nil)
            }
        }
    }
    
    func keyDown(with event: NSEvent) -> NSEvent? {
        guard view.window?.isKeyWindow ?? false else {
            return event
        }

        if Keycodes.enterKey.matches(event: event) || Keycodes.returnKey.matches(event: event) {
            self.playCurrentTrack()
        }
        else {
            return event
        }
        
        return nil
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

        guard !isQueue else {
            let tracksBefore = history.tracks
            history.remove(indices: indices)
            _tableView.animateDifference(from: tracksBefore, to: history.tracks)
            return
        }

        (history.playlist as! PlaylistManual).removeTracks(indices.compactMap { history.track(at: $0) })
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

            view.image = track.rPreview

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
            
            // More detailed
            view.barWidth = 1
            view.spaceWidth = 1
            
            // For the small previews, less fps is enough (for performance)
            view.updateTime = 1 / 10
            view.lerpRatio = 1 / 2
            view.completeTransitionSteps = 6

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
            view.textField?.attributedStringValue = track.rBPM
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.key, let view = tableView.makeView(withIdentifier: CellIdentifiers.key, owner: nil) as? NSTableCellView {
            view.textField?.attributedStringValue = track.rKey
            view.textField?.setAlignment(.center) // Is reset when setting attributed string
            return view
        }
        else if tableColumn?.identifier == ColumnIdentifiers.duration, let view = tableView.makeView(withIdentifier: CellIdentifiers.duration, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = track.rLength 
            return view
        }

        return nil
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        if let track = history.track(at: row) {
            let exists = track.url != nil
            if !exists {
                rowView.backgroundColor = NSColor(white: 0.03, alpha: 1.0)
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return VibrantTableRowView()
    }
    
    @IBAction func showInfo(_ sender: Any?) {
        showTrackInfo(of: Array(_tableView.selectedRowIndexes), nextTo: _tableView.rowView(atRow: _tableView.selectedRow, makeIfNecessary: false))
    }
    
    func showTrackInfo(of: [Int], nextTo: NSView?) {
        // TODO Calculate in background
        if !infoEditor.window!.isVisible {
            infoEditor.window!.positionNextTo(view: (nextTo?.visibleRect != .zero ? nextTo : nil) ?? view)
        }
        
        let tracks = of.map { history.track(at: $0)! }
        infoEditor.show(tracks: tracks)
    }
    
    // Pasteboard, Dragging
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        Library.shared.writeTrack(history.track(at: row)!, toPasteboarditem: item)
        return item
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard !isQueue else {
            return dropOperation == .above ? .move : []
        }
        
        if dropOperation == .above, Library.shared.isEditable(playlist: history.playlist), history.isUnsorted {
            return .move
        }
        return []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard()
        let tracks = (pasteboard.pasteboardItems ?? []).compactMap(Library.shared.readTrack)
        
        if isQueue {
            let tracksBefore = history.tracks
            
            if (info.draggingSource() as AnyObject) === _tableView {
                history.rearrange(tracks: tracks, before: row)
            }
            else {
                history.insert(tracks: tracks, before: row)
            }
            
            _tableView.animateDifference(from: tracksBefore, to: history.tracks)
        }
        else {
            (history.playlist as! PlaylistManual).addTracks(tracks, above: row)
            try! Library.shared.viewContext.save()
        }

        return true
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
                desired.sort = { ($0.bpm ?? 0) < ($1.bpm ?? 0)  }
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
}

extension TrackController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return history.size
    }
}

extension TrackController: NSSearchFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        desired.filter = PlayHistory.filter(findText: _searchField.stringValue)
    }
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        closeSearchBar(self)
    }
}
