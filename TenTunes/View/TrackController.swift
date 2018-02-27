//
//  TrackController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation

class PlayHistorySetup {
    var completion: (PlayHistory) -> Swift.Void
    
    init(completion: @escaping (PlayHistory) -> Swift.Void) {
        self.completion = completion
    }
    
    var semaphore = DispatchSemaphore(value: 1)
    var _changed = false
    
    var filter: ((Track) -> Bool)? {
        didSet {
            _changed = true
        }
    }
    
    var sort: ((Track, Track) -> Bool)? {
        didSet {
            _changed = true
        }
    }
}

class TrackController: NSViewController {
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
    
    @IBOutlet weak var _menuRemoveFromPlaylist: NSMenuItem!
    
    var history: PlayHistory! {
        didSet {
            _tableView.reloadData()
        }
    }
    var desired: PlayHistorySetup!
    
    func addSearchBarItem(title: String, previous: NSView) -> NSButton {
        let button = NSButton()
        button.title = title
        button.bezelStyle = .rounded

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
        desired = PlayHistorySetup { self.history = $0 }
        
        _tableView.registerForDraggedTypes([Track.pasteboardType])

        _searchBarHeight.constant = CGFloat(0)
        
        _sortTitle = addSearchBarItem(title: "Title", previous: _sortLabel)
        _sortKey = addSearchBarItem(title: "Key", previous: _sortTitle)
        _sortBPM = addSearchBarItem(title: "BPM", previous: _sortKey)
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.keyDown(with: $0)
        }
    }
    
    override func viewDidAppear() {
        // Appearance is not yet set in willappear
        if self.view.window!.appearance?.name == NSAppearance.Name.vibrantDark {
            // Table views don't support transparent bg colors, otherwise the labels background color add to it
            // Also it can't be too dark??
            _tableView.backgroundColor = NSColor(white: 0.07, alpha: 1.0)
        }
        else {
            _tableView.backgroundColor = NSColor(white: 0.73, alpha: 1.0)
        }
    }
    
    func set(playlist: Playlist) {
        playlist.calculateTracks() // For folders this is essential
        self.history = PlayHistory(playlist: playlist)
        self.desired._changed = true // The new history doesn't yet have our desireds applied
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
        return row >= 0 ? history.track(at: row) : nil
    }
    
    func playCurrentTrack() {
        if let selectedTrack = selectedTrack, let observer = playTrack {
            observer(selectedTrack, self._tableView.selectedRow)
        }
    }
    
    @IBAction func doubleClick(_ sender: Any) {
        let row = self._tableView.clickedRow
        
        if let playTrack = playTrack {
            if let track = history.track(at: row) {
                playTrack(track, row)
            }
        }
    }
    
    @IBAction func menuPlay(_ sender: Any) {
        self.doubleClick(sender)
    }
    
    @IBAction func menuShowInFinder(_ sender: Any) {
        let row = self._tableView.clickedRow
        let track = history.track(at: row)!
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
        guard let view = view ?? visibleView(to: track), view.track === track else {
            return
        }
        
        view.textField?.stringValue = track.rTitle
        
        view.subtitleTextField?.stringValue = track.rSource
//        view.subtitleTextField?.textColor = NSColor.secondaryLabelColor
        // Is reset for some reason
        view.subtitleTextField?.setStringColor(NSColor.secondaryLabelColor)
        
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
            desired.sort = nil
            return
        }
        
        desired.sort = sorter(byButton: sender)
        
        for other in _sortButtons where other !== sender {
            other.state = .off
        }
    }
    
    func sorter(byButton button: NSButton?) -> ((Track, Track) -> Bool)? {
        guard let button = button else {
            return nil
        }
        
        switch button {
        case _sortTitle:
            return { $0.rTitle < $1.rTitle }
        case _sortKey:
            return { Optional<Key>.compare($0.key, $1.key) }
        case _sortBPM:
            return { ($0.bpm ?? 500) < ($1.bpm ?? 500)  }
        default:
            fatalError("Unknown Button")
        }
    }
    
    func remove(indices: [Int]?) {
        if let indices = indices {
            Library.shared.remove(tracks: indices.flatMap { history.track(at: $0) }, from: history.playlist)
            // Don't reload data, we'll be updated in async
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
        
        let track = history.track(at: row)!

        if tableColumn == tableView.tableColumns[0] {
            if let view = tableView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? TrackCellView {
                view.track = track
                update(view: view, with: track)
                return view
            }
        } else if tableColumn == tableView.tableColumns[1] {
            
        } else if tableColumn == tableView.tableColumns[2] {
            
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
    
    // Pasteboard, Dragging
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        Library.shared.writeTrack(history.track(at: row)!, toPasteboarditem: item)
        return item
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above, Library.shared.isEditable(playlist: history.playlist), history.isUnsorted {
            return .move
        }
        return []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard()
        let tracks = (pasteboard.pasteboardItems ?? []).flatMap(Library.shared.readTrack)
        
        Library.shared.addTracks(tracks, to: history.playlist, above: row)

        return true
    }
}

extension TrackController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return history.size;
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

extension TrackController: NSMenuDelegate {
    var menuTracks: [Track] {
        return _tableView.clickedRows.flatMap { history.track(at: $0) }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        if menuTracks.count < 1 {
            menu.cancelTrackingWithoutAnimation()
        }

        _menuRemoveFromPlaylist.isHidden = !Library.shared.isPlaylist(playlist: history.playlist)
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Probably the main Application menu
        if menuItem.menu?.delegate !== self {
            return validateUserInterfaceItem(menuItem)
        }

        // Right Click Menu
        if menuItem == _menuRemoveFromPlaylist { return Library.shared.isEditable(playlist: history.playlist) }
        
        return true
    }
    
    @IBAction func removeTrack(_ sender: Any) {
        remove(indices: _tableView.clickedRows)
    }
    
    @IBAction func deleteTrack(_ sender: Any) {
        Library.shared.delete(tracks: menuTracks)
    }
}

extension TrackController: NSUserInterfaceValidations {
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard let action = item.action else {
            return false
        }

        if action == #selector(delete as (AnyObject) -> Swift.Void) {
            return Library.shared.isEditable(playlist: history.playlist)
        }

        if action == #selector(performFindPanelAction) { return true }

        return false
    }
    
    @IBAction func delete(_ sender: AnyObject) {
        remove(indices: Array(_tableView.selectedRowIndexes))
    }
    
    @IBAction func performFindPanelAction(_ sender: AnyObject) {
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _searchBarHeight.animator().constant = CGFloat(26)
        })
        _searchField.window?.makeFirstResponder(_searchField)
    }
    
    @IBAction func closeSearchBar(_ sender: Any) {
        desired.filter = nil
        
        _searchField.resignFirstResponder()
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _searchBarHeight.animator().constant = CGFloat(0)
        })
        view.window?.makeFirstResponder(view)
    }
}

