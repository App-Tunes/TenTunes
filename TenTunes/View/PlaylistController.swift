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
    
    override func awakeFromNib() {
        _outlineView.registerForDraggedTypes([Playlist.pasteboardType, Track.pasteboardType])
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
        let createPlaylist = PlaylistManual()
        let (parent, idx) = playlistInsertionPosition
        
        Library.shared.addPlaylist(createPlaylist, to: parent, above: idx)
        select(playlist: createPlaylist, editTitle: true)
        try! Library.shared.viewContext.save()
    }
    
    @IBAction func createGroup(_ sender: Any) {
        let createPlaylist = PlaylistFolder()
        let (parent, idx) = playlistInsertionPosition
        
        // TODO If we select multiple playlists at once, put them in the newly created one
        Library.shared.addPlaylist(createPlaylist, to: parent, above: idx)
        select(playlist: createPlaylist, editTitle: true)
        try! Library.shared.viewContext.save()
    }
    
    func delete(indices: [Int]?) {
        if let indices = indices {
            Library.shared.viewContext.delete(all: indices.flatMap { _outlineView.item(atRow: $0) as? Playlist })
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
    
    // Pasteboard, Dragging
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        let pbitem = NSPasteboardItem()
        Library.shared.writePlaylist(item as! Playlist, toPasteboarditem: pbitem)
        return pbitem
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        guard let type = info.draggingPasteboard().availableType(from: outlineView.registeredDraggedTypes) else {
            return []
        }
        
        switch type {
        case Track.pasteboardType:
            let playlist = item as? Playlist ?? masterPlaylist!
            return Library.shared.isEditable(playlist: playlist) ? .move : []
        case Playlist.pasteboardType:
            // We can always rearrange, except into playlists
            let playlist = item as? Playlist ?? masterPlaylist
            if !(playlist is PlaylistFolder) {
                return []
            }
            return .move
        default:
            fatalError("Unhandled, but registered pasteboard type")
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pasteboard = info.draggingPasteboard()
        
        guard let type = pasteboard.availableType(from: outlineView.registeredDraggedTypes) else {
            return false
        }
        
        let parent = item as? Playlist ?? masterPlaylist!

        switch type {
        case Track.pasteboardType:
            let tracks = (pasteboard.pasteboardItems ?? []).flatMap(Library.shared.readTrack)

            (parent as! PlaylistManual).addTracks(tracks)
            return true
        case Playlist.pasteboardType:
            let playlists = (pasteboard.pasteboardItems ?? []).flatMap(Library.shared.readPlaylist)
            
            for playlist in playlists {
                Library.shared.addPlaylist(playlist, to: parent as! PlaylistFolder, above: index >= 0 ? index : nil)
            }
            break
        default:
            fatalError("Unhandled, but registered pasteboard type")
        }
        
        try! Library.shared.viewContext.save()
        
        return true
    }
}

extension PlaylistController: NSMenuDelegate {
    var menuPlaylists: [Playlist] {
        return _outlineView.clickedRows.flatMap { _outlineView.item(atRow: $0) as? Playlist }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        if menuPlaylists.count < 1 {
            menu.cancelTrackingWithoutAnimation()
        }
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Probably the main Application menu
        if menuItem.target !== self {
            return validateUserInterfaceItem(menuItem)
        }
        
        return true
    }
    
    @IBAction func deletePlaylist(_ sender: Any) {
        delete(indices: _outlineView.clickedRows)
    }
}

extension PlaylistController: NSUserInterfaceValidations {
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard let action = item.action else {
            return false
        }
        
        if action == #selector(delete as (AnyObject) -> Swift.Void) { return true }
        if action == #selector(performFindPanelAction) { return true }

        return false
    }
    
    @IBAction func delete(_ sender: AnyObject) {
        delete(indices: Array(_outlineView.selectedRowIndexes))
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
