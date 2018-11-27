//
//  PlaylistController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol PlaylistControllerDelegate {
    func playlistController(_ controller: PlaylistController, selectionDidChange playlists: [PlaylistProtocol])
    func playlistController(_ controller: PlaylistController, play playlist: PlaylistProtocol)
}

@objc class PlaylistController: NSViewController {
    var masterPlaylist: PlaylistFolder? {
        didSet {
            _outlineView?.reloadData()
            
            // Needs to be done here, otherwise the items are ignored
            _outlineView.autosaveName = .init("PlaylistController")
            _outlineView.autosaveExpandedItems = true
        }
    }
    var library: PlaylistLibrary? {
        didSet {
            _outlineView?.reloadData()
            
            if history.current == .library {
                delegate?.playlistController(self, selectionDidChange: [library!])
            }
        }
    }
    
    var history: History<SelectionMoment> = History(default: .library)
    
    var delegate: PlaylistControllerDelegate?
    
    @IBOutlet var _outlineView: NSOutlineView!
    
    @IBOutlet var _back: NSButton!
    @IBOutlet var _forwards: NSButton!
    
    @IBOutlet var _addPlaylist: SMButtonWithMenu!
    @IBOutlet var _addGroup: SMButtonWithMenu!
    
    var selectedPlaylists: [(Int, Playlist)] {
        return _outlineView.selectedRowIndexes.map {
            return ($0, _outlineView.item(atRow: $0) as! Playlist)
        }
    }
    
    override func awakeFromNib() {
        _outlineView.registerForDraggedTypes(pasteboardTypes)
        
        _addPlaylist.hoverImage = NSImage(named: .init("caret-down"))?.tinted(in: .lightGray)
        _addPlaylist.idleImage = NSImage(named: .init("add"))?.tinted(in: .lightGray)
        
        _addGroup.hoverImage = _addPlaylist.hoverImage
        _addGroup.idleImage = _addPlaylist.idleImage
        
        registerObservers()
    }
    
    @IBAction func didClick(_ sender: Any) {
    }
    
    @IBAction func didDoubleClick(_ sender: Any) {
        let clicked = _outlineView.clickedRow
        if clicked >= 0 {
            let playlist = _outlineView.item(atRow: clicked) as! Playlist
            
            if outlineView(_outlineView, isItemExpandable: playlist) {
                _outlineView.toggleItemExpanded(playlist)
            }
            else {
                delegate?.playlistController(self, play: playlist)
            }
        }
    }
    
    @IBAction func selectLibrary(_ sender: Any) {
        select(.library)
    }
    
    @IBAction func performFindPanelAction(_ sender: AnyObject) {
        // Search the current playlist
        // TODO A little too omniscient
        ViewController.shared.trackController.performFindPanelAction(sender)
    }
    
    var playlistInsertionPosition: (PlaylistFolder, Int?) {
        if let idx = _outlineView.selectedRowIndexes.last {
            let selectedPlaylist = _outlineView.item(atRow: idx) as! Playlist
            
            if let selectedPlaylist = selectedPlaylist as? PlaylistFolder {
                // Add inside, as last
                return (selectedPlaylist, nil)
            }
            else {
                // Add below
                let (parent, idx) = Library.shared.position(of: selectedPlaylist)!
                return (parent, idx + 1)
            }
        }
        else {
            return (masterPlaylist!, nil)
        }
    }
    
    func playlist(fromItem: Any?) -> PlaylistProtocol? {
        return (fromItem ?? (masterPlaylist as Any?)) as? PlaylistProtocol
    }

    func select(playlist: Playlist, editTitle: Bool = false) {
        select(.playlists([playlist]))
        
        guard editTitle else {
            return
        }
        
        let idx = _outlineView.row(forItem: playlist)
        
        guard idx >= 0 else {
            fatalError("Playlist does not exist in view even though it must!")
        }
        
        _outlineView.edit(row: idx, with: nil, select: true)
    }
    
    func select(_ selection: SelectionMoment) {
        switch selection {
        case .library:
            _outlineView.deselectAll(self)
            didSelect(.library)
        case .playlists(let playlists):
            // Expand so all items are in view
            let paths = playlists.map(Library.shared.path)
            for path in paths {
                for parent in path.dropLast() {
                    _outlineView.expandItem(parent)
                }
            }
            
            // First selection, for most cases this is enough, but there's no better way anyway
            let indices: [IndexSet.Element] = playlists.compactMap {
                let idx = self._outlineView.row(forItem: $0)
                return idx >= 0 ? idx : nil
            }
            
            if let first = indices.first { _outlineView.scrollRowToVisible(first) }
            // didSelect will be called automatically by delegate method
            _outlineView.selectRowIndexes(IndexSet(indices), byExtendingSelection: false)
        }
    }
    
    func didSelect(_ selection: SelectionMoment) {
        guard selection != history.current else {
            return
        }
        
        history.push(selection)
    }
    
    func insert(playlist: Playlist) {
        let (parent, idx) = playlistInsertionPosition
        parent.addPlaylist(playlist, above: idx)
    }
    
    @IBAction func createPlaylist(_ sender: Any) {
        insert(playlist: PlaylistManual(context: Library.shared.viewContext))
        try! Library.shared.viewContext.save()
    }
    
    @IBAction func createSmartPlaylist(_ sender: Any) {
        insert(playlist: PlaylistSmart(context: Library.shared.viewContext))
        try! Library.shared.viewContext.save()
    }
    
    @IBAction func createGroup(_ sender: Any) {
        let selected = selectedPlaylists
        let group = PlaylistFolder(context: Library.shared.viewContext)
        
        insert(playlist: group)

        if selected.count > 1, selected.map({ $0.1.parent }).uniqueElement != nil {
            for (_, playlist) in selected {
                group.addPlaylist(playlist)
            }
        }
        
        try! Library.shared.viewContext.save()
    }
    
    @IBAction func createCartesianPlaylist(_ sender: Any) {
        insert(playlist: PlaylistCartesian(context: Library.shared.viewContext))
        try! Library.shared.viewContext.save()
    }
    
    func delete(indices: [Int]?, confirmed: Bool = true) {
        guard let playlists = indices?.compactMap({ _outlineView.item(atRow: $0) as? Playlist }) else {
            return
        }

        let message = "Are you sure you want to delete \(playlists.count) playlist\(playlists.count > 1 ? "s" : "")?"
        guard !confirmed || NSAlert.ensure(intent: playlists.allSatisfy { $0.isTrivial }, action: "Delete Playlists", text: message) else {
            return
        }
        
        guard playlists.allSatisfy({ Library.shared.isPlaylist(playlist: $0) }) else {
            fatalError("Trying to delete undeletable playlists!")
        }
        
        Library.shared.viewContext.delete(all: playlists)
        try! Library.shared.viewContext.save()
    }
    
    @IBAction func back(_ sender: Any) {
        history.back(skip: { !$0.isValid })
        select(history.current)
    }
    
    @IBAction func forwards(_ sender: Any) {
        history.forwards(skip: { !$0.isValid })
        select(history.current)
    }
}

extension PlaylistController : NSOutlineViewDataSource {
    enum CellIdentifiers {
        static let NameCell = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let playlist = self.playlist(fromItem: item) else {
            return 0  // Not initialized yet
        }
        
        return (playlist as! PlaylistFolder).childrenList.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let playlist = item as! Playlist
        
        if let view = outlineView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = playlist.name
            view.imageView?.image = Library.shared.icon(of: playlist)

            // Doesn't work from interface builder
            view.textField?.delegate = self
            view.textField?.target = self
            view.textField?.action = #selector(editPlaylistTitle)
            view.textField?.isEditable = Library.shared.isPlaylist(playlist: playlist)
            return view
        }
        
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let playlist = self.playlist(fromItem: item)!
        
        return (playlist as! PlaylistFolder).childrenList[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return item as! Playlist
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is PlaylistFolder
    }
    
    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        return Library.shared.writePlaylistID(of: item as! Playlist)
    }
    
    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        return Library.shared.restoreFrom(playlistID: object)
    }
}

extension PlaylistController : NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !_outlineView.selectedRowIndexes.isEmpty else {
            return
        }
        
        didSelect(.playlists(_outlineView.selectedRowIndexes.map { self._outlineView.item(atRow: $0) as! Playlist }))
    }
    
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        return SubtleTableRowView()
    }
}

extension PlaylistController: NSTextFieldDelegate {
    // Editing
    
    @IBAction func editPlaylistTitle(_ sender: Any?) {
        let textField = sender as! NSTextField
        textField.resignFirstResponder()
        
        let row = _outlineView.row(for: textField.superview!)
        if let playlist = (_outlineView.item(atRow: row)) as? Playlist {
            if playlist.name != textField.stringValue {
                playlist.name = textField.stringValue
            }
        }
        else {
            print("Unable to find Playlist after editing!")
        }
    }
}

extension PlaylistController {
    enum SelectionMoment : Equatable, ExposedAssociatedValues {
        case library
        case playlists(_ playlists: [Playlist])
        
        func playlists(library: PlaylistProtocol) -> [PlaylistProtocol] {
            switch self {
            case .library:
                return [library]
            case .playlists(let playlists):
                return playlists
            }
        }
        
        var isValid: Bool {
            switch self {
            case .library:
                return true
            case .playlists(let playlists):
                return playlists.noneSatisfy { $0.isDeleted }
            }
        }
    }
}
