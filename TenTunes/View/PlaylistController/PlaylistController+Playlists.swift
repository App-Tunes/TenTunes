//
//  PlaylistController+Playlists.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 02.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension PlaylistController.Item {
    class PlaylistItem : PlaylistController.Folder {
        let playlist: Playlist
        
        init(_ playlist: Playlist, parent: PlaylistController.Item?, placeholderChild: Bool = false) {
            self.playlist = playlist
            super.init(parent: parent)
            self.placeholderChild = placeholderChild
        }
        
        override var asPlaylist: Playlist? {
            return playlist
        }
        
        override var title: String {
            return playlist.name
        }
        
        override var isFolder: Bool { return playlist is PlaylistFolder }

        override var isEmpty: Bool {
            return ((playlist as? PlaylistFolder)?.children.count ?? 0) == 0
        }
        
        override func children(cache: PlaylistController.Cache) -> [Child] {
            guard let folder = playlist as? PlaylistFolder else {
                return []
            }
            
            return folder.childrenList.map(cache.playlistItem)
        }
        
        override var isValid: Bool {
            return !playlist.isDeleted && playlist.managedObjectContext != nil
        }
        
        override var icon: NSImage {
            return Library.shared.icon(of: playlist)
        }
        
        class func persistentID(for playlist: Playlist) -> String {
            return Library.shared.export().stringID(of: playlist)
        }
        
        override var persistentID: String {
            return PlaylistItem.persistentID(for: playlist)
        }
        
        override func load(id: String, cache: PlaylistController.Cache) -> Child? {
            return Library.shared.import().playlist(id: playlist)
                .map(cache.playlistItem)
        }
        
        override func accepts(item: Child) -> Bool {
            return true
        }
    }
}

extension PlaylistController {
    enum CellIdentifiers {
        static let NameCell = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
        static let CategoryCell = NSUserInterfaceItemIdentifier(rawValue: "categoryCell")
        static let PlaceholderCell = NSUserInterfaceItemIdentifier(rawValue: "placeholderCell")
    }

    @IBAction func didClick(_ sender: Any) {
    }
    
    @IBAction func didDoubleClick(_ sender: Any) {
        let clicked = _outlineView.clickedRow
        guard clicked >= 0 else {
            return
        }
        
        let item = _outlineView.item(atRow: clicked) as! Item
        
        guard !outlineView(_outlineView, isItemExpandable: item) else {
            _outlineView.toggleItemExpanded(item)
            return
        }
        
        if let item = item as? Item.PlaylistItem {
            // TODO Generify
            delegate?.playlistController(self, play: item.playlist)
        }
    }
    
    func playlistInsertionPosition(row: Int?, allowInside: Bool = true) -> (PlaylistFolder, Int?) {
        guard  let idx = row else {
            return (defaultPlaylist!, nil)
        }
        
        let selectedItem = _outlineView.item(atRow: idx) as! Item
        
        guard let playlist = (selectedItem as? Item.PlaylistItem)?.playlist else {
            return (defaultPlaylist!, nil)
        }
        
        if allowInside, let folder = playlist as? PlaylistFolder {
            // Add inside, as last
            return (folder, nil)
        }
        else {
            // Add below
            let (parent, idx) = Library.shared.position(of: playlist)!
            return (parent, idx + 1)
        }
    }
    
    func select(playlist: Playlist, editTitle: Bool = false) {
        let item = cache.playlistItem(playlist)
        
        select(.items([item]))
        
        guard editTitle else {
            return
        }
        
        guard let idx = _outlineView.orow(forItem: item) else {
            fatalError("Playlist does not exist in view even though it must!")
        }
        
        _outlineView.edit(row: idx, with: nil, select: true)
    }
    
    func select(_ selection: SelectionMoment) {
        switch selection {
        case .master:
            _outlineView.deselectAll(self)
            didSelect(.master)
        case .items(let items):
            let playlists = items.compactMap { $0.asPlaylist }
            
            // Expand so all items are in view
            let paths = playlists.map { $0.path }
            for path in paths {
                for parent in path.dropLast() {
                    _outlineView.expandItem(cache.playlistItem(parent))
                }
            }
            
            // First selection, for most cases this is enough, but there's no better way anyway
            let indices: [IndexSet.Element] = playlists.compactMap {
                return _outlineView.row(forItem: cache.playlistItem($0))
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
        let (parent, idx) = playlistInsertionPosition(row: _outlineView.selectedRowIndexes.last)
        parent.addPlaylist(playlist, above: idx)
    }
    
    func delete(indices: [Int]?, confirmed: Bool = true) {
        guard let playlists = indices?.compactMap({ (_outlineView.item(atRow: $0) as! Item).asPlaylist }) else {
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
}

extension PlaylistController : NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = self.item(raw: item) as? Folder else {
            return 0
        }
        
        if item.placeholderChild, item.isEmpty {
            return 1
        }
        
        return item.children(cache: cache).count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let item = self.item(raw: item) as! Folder

        if item.isEmpty {
            return item.placeholder!
        }

        return item.children(cache: cache)[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return item as! Item
    }
    
    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        return (item as! Item).persistentID
    }
    
    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        return (object as? String).flatMap { masterItem?.load(id: $0, cache: self.cache) }
    }
}

extension PlaylistController : NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let item = item as! Item
        
        if item is Placeholder {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.PlaceholderCell, owner: nil) as? NSTableCellView {
                view.textField?.stringValue = item.title
                
                return view
            }
        }
        else if item.parent == masterItem {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.CategoryCell, owner: nil) as? NSTableCellView {
                view.textField?.stringValue = item.title
                view.imageView?.image = item.icon
                
                return view
            }
        }
        else {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? NSTableCellView {
                let enabled = item.enabled

                view.textField?.stringValue = item.title
                view.imageView?.image = item.icon

                view.textField?.textColor = enabled ? .labelColor : .disabledControlTextColor
                if #available(OSX 10.14, *) {
                    view.imageView?.contentTintColor = enabled ? nil : .disabledControlTextColor
                }
                
                if enabled, item is Item.PlaylistItem {
                    // Doesn't work from interface builder
                    view.textField?.delegate = self
                    view.textField?.target = self
                    view.textField?.action = #selector(editPlaylistTitle)
                    view.textField?.isEditable = (item.asAnyPlaylist ?=> Library.shared.isPlaylist) ?? false
                }
                
                return view
            }
        }

        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return (item as? Folder)?.isFolder ?? false
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !_outlineView.selectedRowIndexes.isEmpty else {
            return
        }
        
        didSelect(.items(_outlineView.selectedRowIndexes.map { self._outlineView.item(atRow: $0) as! Item }))
    }
    
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        return SubtleTableRowView()
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        let item = item as! Item
        return item.parent != masterItem && item.enabled
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        let item = item as! Item
        
        guard item.parent == masterItem else {
            return 17
        }
        
        return 25
    }
}

extension PlaylistController: NSTextFieldDelegate {
    // Editing
    
    @IBAction func editPlaylistTitle(_ sender: Any?) {
        let textField = sender as! NSTextField
        textField.resignFirstResponder()
        
        let row = _outlineView.row(for: textField.superview!)
        if let playlist = (_outlineView.item(atRow: row) as! Item).asPlaylist {
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
        case master
        case items(_ items: [Item])
        
        static func == (lhs: PlaylistController.SelectionMoment, rhs: PlaylistController.SelectionMoment) -> Bool {
            return lhs.comparable() == rhs.comparable()
        }

        func items(master: Item) -> [Item] {
            switch self {
            case .master:
                return [master]
            case .items(let items):
                return items
            }
        }
        
        private func comparable() -> [Item]? {
            switch self {
            case .master:
                return nil
            case .items(let items):
                return items
            }
        }
        
        var isValid: Bool {
            switch self {
            case .master:
                return true
            case .items(let items):
                return items.allSatisfy { $0.isValid }
            }
        }
    }
}
