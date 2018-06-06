//
//  PlaylistController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc class PlaylistController: NSViewController {
    var masterPlaylist: PlaylistFolder? {
        didSet { _outlineView.reloadData() }
    }
    var library: PlaylistLibrary? {
        didSet { _outlineView.reloadData() }
    }

    var selectionDidChange: ((PlaylistProtocol) -> Swift.Void)? = nil
    var playPlaylist: ((PlaylistProtocol) -> Swift.Void)? = nil
    
    @IBOutlet var _outlineView: NSOutlineView!
    
    var selectedPlaylists: [(Int, Playlist)] {
        return _outlineView.selectedRowIndexes.map {
            return ($0, _outlineView.item(atRow: $0) as! Playlist)
        }
    }
    
    override func awakeFromNib() {
        _outlineView.registerForDraggedTypes(pasteboardTypes)
    }
    
    @IBAction func didClick(_ sender: Any) {
    }
    
    @IBAction func didDoubleClick(_ sender: Any) {
        let clicked = _outlineView.clickedRow
        if let playPlaylist = playPlaylist, clicked >= 0 {
            playPlaylist(_outlineView.item(atRow: clicked) as! Playlist)
        }
    }
    
    @IBAction func selectLibrary(_ sender: Any) {
        if let selectionDidChange = selectionDidChange, let library = library {
            selectionDidChange(library)
        }
        _outlineView.deselectAll(self)
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
        // Select
        // If we created in a closed folder it might not exist
        
        let path = Library.shared.path(of: playlist)
        for parent in path.dropLast() {
            _outlineView.expandItem(parent)
        }
        
        let idx = _outlineView.row(forItem: playlist)
        if idx < 0 { fatalError("Playlist does not exist in view even though it must!") }
        
        _outlineView.selectRowIndexes(IndexSet(integer: idx), byExtendingSelection: false)
        
        if editTitle {
            _outlineView.edit(row: idx, with: nil, select: true)
        }
    }
    
    @IBAction func createPlaylist(_ sender: Any) {
        let createPlaylist = PlaylistManual(context: Library.shared.viewContext)
        Library.shared.viewContext.insert(createPlaylist)
        let (parent, idx) = playlistInsertionPosition
        
        parent.addPlaylist(createPlaylist, above: idx)
        try! Library.shared.viewContext.save()

        select(playlist: createPlaylist, editTitle: true)
    }
    
    @IBAction func createGroup(_ sender: Any) {
        let createPlaylist = PlaylistFolder(context: Library.shared.viewContext)
        Library.shared.viewContext.insert(createPlaylist)
        let (parent, idx) = playlistInsertionPosition
        
        // TODO If we select multiple playlists at once, put them in the newly created one
        parent.addPlaylist(createPlaylist, above: idx)
        try! Library.shared.viewContext.save()

        select(playlist: createPlaylist, editTitle: true)
    }
    
    func delete(indices: [Int]?) {
        if let indices = indices {
            Library.shared.viewContext.delete(all: indices.compactMap { _outlineView.item(atRow: $0) as? Playlist })
            try! Library.shared.viewContext.save()
        }
    }
}

extension PlaylistController : NSOutlineViewDataSource {
    fileprivate enum CellIdentifiers {
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
            view.imageView?.image = playlist.icon

            // Doesn't work from interface builder
            view.textField?.delegate = self
            view.textField?.target = self
            view.textField?.action = #selector(editPlaylistTitle)
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
        // TODO If we select multiple, show all at once?
        if let selected = _outlineView.selectedRowIndexes.first {
            if let selectionDidChange = selectionDidChange {
                selectionDidChange(_outlineView.item(atRow: selected) as! Playlist)
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        return VibrantTableRowView()
    }
}

extension PlaylistController: NSTextFieldDelegate {
    // Editing
    
    @IBAction func editPlaylistTitle(_ sender: Any?) {
        let textField = sender as! NSTextField
        textField.resignFirstResponder()
        
        let row = _outlineView.row(for: textField.superview!)
        let playlist = (_outlineView.item(atRow: row)) as! Playlist
        playlist.name = textField.stringValue
        
        try! Library.shared.viewContext.save()
    }
}
