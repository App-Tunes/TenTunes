//
//  PlaylistController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc class PlaylistController: NSObject {
    var playlists: [Playlist] = [] {
        didSet {
            self._outlineView.reloadData()
        }
    }
    var _playlistSelected: ((Playlist) -> Swift.Void)? = nil
    
    @IBOutlet var _outlineView: NSOutlineView!
    
    func setObserver(block: @escaping (Playlist) -> Swift.Void) {
        self._playlistSelected = block
    }
    
    @IBAction func didClick(_ sender: Any) {
    }
}

extension PlaylistController : NSOutlineViewDataSource {
    fileprivate enum CellIdentifiers {
        static let NameCell = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item as? Playlist else {
            return self.playlists.count
        }
        return item.children.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let playlist = item as! Playlist
        
        if let view = outlineView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = playlist.name
            view.imageView?.image = NSImage(named: NSImage.Name(rawValue: playlist.children.count > 0 ? "folder" : "playlist"))!
            return view
        }
        
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let playlists = ((item as? Playlist)?.children) ?? self.playlists
        
        return playlists[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let playlist = item as! Playlist
        return playlist.children.count > 0
    }
}

extension PlaylistController : NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if let selected = _outlineView.selectedRowIndexes.first {
            if let observer = self._playlistSelected {
                observer(_outlineView.item(atRow: selected) as! Playlist)
            }
        }
    }
}

