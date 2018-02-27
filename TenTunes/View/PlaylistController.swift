//
//  PlaylistController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc class PlaylistController: NSObject {
    var masterPlaylist: Playlist = Playlist(folder: true) {
        didSet {
            self._outlineView.reloadData()
        }
    }
    var library: Playlist = Playlist(folder: true)

    var selectionDidChange: ((Playlist) -> Swift.Void)? = nil
    var playPlaylist: ((Playlist) -> Swift.Void)? = nil
    
    @IBOutlet var _outlineView: NSOutlineView!
    
    @IBAction func didClick(_ sender: Any) {
    }
    
    @IBAction func didDoubleClick(_ sender: Any) {
        if let playPlaylist = playPlaylist {
            playPlaylist(_outlineView.item(atRow: _outlineView.clickedRow) as! Playlist)
        }
    }
    
    @IBAction func selectLibrary(_ sender: Any) {
        if let selectionDidChange = selectionDidChange {
            selectionDidChange(library)
        }
        _outlineView.deselectAll(self)
    }
    
    @IBAction func createPlaylist(_ sender: Any) {
        let idx = _outlineView.selectedRowIndexes.last
        let createPlaylist = Playlist(folder: false)
        
        // Add to parent
        if let idx = idx {
            let selectedPlaylist = _outlineView.item(atRow: idx) as! Playlist
            
            if selectedPlaylist.isFolder {
                // Insert as first
                Library.shared.add(playlist: createPlaylist, to: selectedPlaylist)
            }
            else {
                // Add below
                let (parent, idx) = Library.shared.position(of: selectedPlaylist)!
                Library.shared.add(playlist: createPlaylist, to: parent, at: idx + 1)
            }
        }
        else {
            Library.shared.add(playlist: createPlaylist)
        }
        
        // Select
        // TODO Expand
        // TODO Edit Title 
        // If we created in a closed folder it might not exist
        let createdIndex = _outlineView.row(forItem: createPlaylist)
        if createdIndex >= 0 {
            _outlineView.selectRowIndexes(IndexSet(integer: createdIndex), byExtendingSelection: false)
        }
    }
    
    @IBAction func createGroup(_ sender: Any) {
    }
}

extension PlaylistController : NSOutlineViewDataSource {
    fileprivate enum CellIdentifiers {
        static let NameCell = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item as? Playlist else {
            return masterPlaylist.children!.count
        }
        return item.children!.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let playlist = item as! Playlist
        
        if let view = outlineView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = playlist.name
            view.imageView?.image = NSImage(named: NSImage.Name(rawValue: playlist.isFolder ? "folder" : "playlist"))!
            return view
        }
        
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let playlists = ((item as? Playlist)?.children!) ?? masterPlaylist.children!
        
        return playlists[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let playlist = item as! Playlist
        return playlist.isFolder
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

extension PlaylistController: NSMenuDelegate {
    var menuPlaylists: [Playlist] {
        return _outlineView.clickedRows.flatMap { _outlineView.item(atRow: $0) as? Playlist }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        if menuPlaylists.count < 1 {
            menu.cancelTrackingWithoutAnimation()
        }
    }
    
    @IBAction func deletePlaylist(_ sender: Any) {
        Library.shared.delete(playlists: menuPlaylists)
    }
}
