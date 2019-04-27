//
//  CategoryController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension CategoryController {
    class Item : ValidatableItem {
        var isValid: Bool { return true }
    }
    
    class Cache: CacheRegistry<Item> {
        func track(_ track: Track) -> TrackItem {
            return get(TrackItem.persistentID(for: track)) {_ in
                return TrackItem(track)
            } as! CategoryController.TrackItem
        }
    }
    
    class Category: Item {
        var title: String { fatalError() }
        var subtitle: String { fatalError() }

        var icon: NSImage { fatalError() }
        var tracks: [Track] { fatalError() }
        
        func children(cache: Cache) -> [TrackItem] {
            return tracks.map(cache.track)
        }
    }
    
    class TrackItem: Item {
        let track: Track
        
        init(_ track: Track) {
            self.track = track
        }
        
        class func persistentID(for track: Track) -> String {
            return Library.shared.export().stringID(of: track)
        }
        
        override var isValid: Bool { return !track.wasDeleted }
    }
}

class CategoryController: NSViewController {
    @IBOutlet var _outlineView: NSOutlineView!
    
    let cache = Cache()
    
    var categories: [Category] = [] {
        didSet { _outlineView.reloadData() }
    }
    
    override func awakeFromNib() {
        _outlineView.enclosingScrollView?.backgroundColor = view.byAppearance([
            nil: NSColor(white: 0.73, alpha: 1.0),
            .vibrantDark: NSColor(white: 0.09, alpha: 1.0),
        ])
    }
    
    override func viewDidAppear() {
        _outlineView.backgroundColor = NSColor.clear
    }
}
