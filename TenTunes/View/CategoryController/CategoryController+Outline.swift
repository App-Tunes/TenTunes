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
}
