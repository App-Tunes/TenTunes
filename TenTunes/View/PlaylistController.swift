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
        if let selected = _outlineView.selectedRowIndexes.first {
            if let selectionDidChange = selectionDidChange {
                selectionDidChange(_outlineView.item(atRow: selected) as! Playlist)
            }
        }
    }
}

