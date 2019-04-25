//
//  PlaylistController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol PlaylistControllerDelegate : class {
    func playlistController(_ controller: PlaylistController, selectionDidChange playlists: [AnyPlaylist])
    func playlistController(_ controller: PlaylistController, play playlist: AnyPlaylist)
}

@objc class PlaylistController: NSViewController {
    let cache = Cache()
    
    var masterItem: Folder? {
        didSet {
            _outlineView?.reloadData()
            
            // Needs to be done here, otherwise the items are ignored
            _outlineView.autosaveName = .init("PlaylistController")
            _outlineView.autosaveExpandedItems = true
        }
    }
    var defaultPlaylist: PlaylistFolder?
    
    var history: History<SelectionMoment> = History(default: .master)
    
    weak var delegate: PlaylistControllerDelegate?
    
    @IBOutlet var _outlineView: NSOutlineView!
    
    @IBOutlet var _home: NSButton!
    @IBOutlet var _back: NSButton!
    @IBOutlet var _forwards: NSButton!
    
    @IBOutlet var _addPlaylist: SMButtonWithMenu!
    @IBOutlet var _addGroup: SMButtonWithMenu!
    
    @IBOutlet var _emptyPlaylistMenu: NSMenu!
    
    var selectedPlaylists: [(Int, Playlist)] {
        return _outlineView.selectedRowIndexes.compactMap {
            guard let playlist = (_outlineView.item(atRow: $0) as! Item).asPlaylist else {
                return nil
            }
            return ($0, playlist)
        }
    }
    
    override func awakeFromNib() {
        _outlineView.registerForDraggedTypes(pasteboardTypes)
        
        _addPlaylist.hoverImage = NSImage(named: "caret-down")?.tinted(in: .lightGray)
        _addPlaylist.idleImage = NSImage(named: "add")?.tinted(in: .lightGray)
        
        _addGroup.hoverImage = _addPlaylist.hoverImage
        _addGroup.idleImage = _addPlaylist.idleImage
        
        registerObservers()
    }
        
    @IBAction func selectLibrary(_ sender: Any) {
        select(.master)
    }
    
    @IBAction func performFindPanelAction(_ sender: AnyObject) {
        // Search the current playlist
        // TODO A little too omniscient
        ViewController.shared.trackController.performFindPanelAction(sender)
    }
        
    func item(raw: Any?) -> Item? {
        return raw != nil ? (raw as! Item) : masterItem
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
                group.addToChildren(playlist)
            }
        }
        
        try! Library.shared.viewContext.save()
    }
    
    @IBAction func createCartesianPlaylist(_ sender: Any) {
        insert(playlist: PlaylistCartesian(context: Library.shared.viewContext))
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

extension PlaylistController {
    class Cache : CacheRegistry<Item> {        
        func _playlistItem(_ playlist: Playlist, placeholderChild: Bool) -> Item.PlaylistItem {
            return get(Item.PlaylistItem.persistentID(for: playlist)) { _ in
                Item.PlaylistItem(playlist, parent: playlist.parent ?=> playlistItem, placeholderChild: placeholderChild)
                } as! PlaylistController.Item.PlaylistItem
        }
        
        func playlistItem(_ playlist: Playlist) -> Item.PlaylistItem {
            return _playlistItem(playlist, placeholderChild: false)
        }
        
        func categoryPlaylistItem(_ playlist: Playlist) -> Item.PlaylistItem {
            return _playlistItem(playlist, placeholderChild: true)
        }
    }
}
