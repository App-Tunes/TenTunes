//
//  CategoryController+Category.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension CategoryController {
    enum CellIdentifiers {
        static let CategoryCell = NSUserInterfaceItemIdentifier(rawValue: "categoryCell")
        static let TrackCell = NSUserInterfaceItemIdentifier(rawValue: "trackCell")
    }
}

extension CategoryController {
    func context(forItem item: TrackItem) -> TrackActions.Context {
        let parent = _outlineView.parent(forItem: item) as! Category
        // TODO Add everything above track
        // Drop everything before track
        let tracks = Array(parent.tracks.drop { $0 != item.track })
        return .none(tracks: tracks)
    }
    
    @IBAction
    func doubleClick(_ sender: AnyObject?) {
        guard _outlineView.clickedRow >= 0, let item = _outlineView.item(atRow: _outlineView.clickedRow) as? Item else {
            return
        }
        
        if let item = item as? Category {
            _outlineView.toggleItemExpanded(item)
        }
        else if let item = item as? TrackItem {
            TrackActions.create(context(forItem: item))?.menuPlay(self)
        }
    }
}

extension CategoryController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item as! Item? else {
            return categories.count
        }
        
        return (item as? Category)?.children(cache: cache).count ?? 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item as! Category? else {
            return categories[index]
        }
        
        return item.children(cache: cache)[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is Category
    }
}

extension CategoryController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let item = item as! Item
        
        if let category = item as? Category {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.CategoryCell, owner: nil) as? TitleSubtitleCellView {
                view.textField?.stringValue = category.title
                view.subtitleTextField?.stringValue = category.subtitle

                view.imageView?.image = category.icon
                view.imageView ?=> StylerMyler.makeRoundRect

                return view
            }
        }
        else if let track = (item as? TrackItem)?.track {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.TrackCell, owner: nil) as? NSTableCellView {
                view.textField?.stringValue = track.rTitle
                
                return view
            }
        }
        
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return (item is Category) ? 35 : 17
    }
    
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        return SubtleTableRowView()
    }
    
    @IBAction
    func playAll(_ sender: AnyObject?) {
        guard let item = sender?.representedObject as? Category else {
            return
        }
        
        TrackActions.create(.none(tracks: item.tracks))?.menuPlay(self)
    }
}

extension CategoryController : NSMenuDelegate {
    var menuItems: [Item] {
        return _outlineView.clickedRows.compactMap { _outlineView.item(atRow: $0) as? Item }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        if let items = menuItems as? [TrackItem] {
            let context: TrackActions.Context = (items.onlyElement ?=> self.context)
                ?? .none(tracks: items.map { $0.track })
            trackActions = TrackActions.create(context)
            trackActions?.hijack(menu: menu)
            return
        }
        
        guard let item = menuItems.onlyElement else {
            menu.cancelTrackingWithoutAnimation()
            return
        }

        menu.removeAllItems()

        if let item = item as? Category {
            let playAllItem = NSMenuItem(title: "Play All", action: #selector(playAll(_:)), target: self)
            playAllItem.representedObject = item
            menu.addItem(playAllItem)
        }

        item.addMenuItems(to: menu)

        if menu.items.isEmpty {
            menu.cancelTrackingWithoutAnimation()
        }
    }
}
