//
//  PlaylistController+Index.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension PlaylistController {
    class Item : ValidatableItem, Hashable {
        var title: String { fatalError() }
        var icon: NSImage { fatalError() }
        
        var isValid: Bool { return true }
        var persistentID: String { fatalError() }
        
        var enabled: Bool { return true }
        
        // TODO Generify everything using this
        var asPlaylist: Playlist? { return nil }
        var asAnyPlaylist: AnyPlaylist? { return asPlaylist }
        
        weak var parent: Item?
        
        init(parent: Item? = nil) {
            self.parent = parent
        }
        
        var path: [Item] {
            var path = [self]
            while let current = path.first, let parent = current.parent {
                path.insert(parent, at: 0)
            }
            return path
        }
        
        static func == (lhs: PlaylistController.Item, rhs: PlaylistController.Item) -> Bool {
            return lhs.persistentID == rhs.persistentID
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(persistentID)
        }
    }
    
    class Folder : Item {
        typealias Child = Item
        
        var placeholderChild: Bool = false
        var placeholder: PlaylistController.Placeholder! = nil

        override init(parent: Item? = nil) {
            super.init(parent: parent)
            self.placeholder = .init(parent: self)
        }
        
        var isFolder: Bool { return true }
        
        var isEmpty: Bool { fatalError() }
        
        func children(cache: PlaylistController.Cache) -> [Child] { fatalError() }
        // TODO
        func load(id: String, cache: PlaylistController.Cache) -> Child? { fatalError() }
        
        // TODO
        func accepts(item: Child) -> Bool { fatalError() }
        // TODO
        func add(items: [Child], at: Int = 0) { fatalError() }
    }
    
    class Placeholder : Item {
        override var title: String { return "There is nothing here yet!" }
        
        override var persistentID: String {
            return (parent?.persistentID ?? "") + ".placeholder"
        }
        
        override var isValid: Bool { return (parent as! Folder).isEmpty }
    }
}

extension PlaylistController.Item {
    class Preloaded: PlaylistController.Folder {
        var items: [PlaylistController.Item] = [] {
            didSet {
                for item in items {
                    item.parent = self
                }
            }
        }
        
        init(items: [PlaylistController.Item] = []) {
            self.items = items
            super.init()
        }
        
        override var isEmpty: Bool { return items.isEmpty }
        
        override func children(cache: PlaylistController.Cache) -> [Child] {
            return items
        }
        
        override func load(id: String, cache: PlaylistController.Cache) -> Child? {
            if let match = items.filter({ $0.persistentID == id }).first {
                return match
            }
            
            // TODO Generify?
            return PlaylistItem.load(id: id, cache: cache)
        }
        
        override func accepts(item: Child) -> Bool {
            return items.contains(item)
        }
        
        override func add(items: [Child], at: Int? = nil) {
            self.items.append(contentsOf: items)
            if let index = at {
                self.items.rearrange(elements: items, to: index)
            }
        }
    }
    
    class MasterItem: Preloaded {
        var playlist: AnyPlaylist
        
        init(playlist: AnyPlaylist, items: [PlaylistController.Item] = []) {
            self.playlist = playlist
            super.init(items: items)
        }
        
        override var title: String { return "Library" }
        
        override var icon: NSImage { return NSImage(named: .homeName)! }
        
        override var persistentID: String { return "Master" }

        override var asAnyPlaylist: AnyPlaylist? { return playlist }
    }
    
    class MasterAlias: PlaylistController.Item {
        weak var original: MasterItem?
        
        init(_ original: MasterItem) {
            self.original = original
        }
        
        override var title: String { return original?.title ?? "" }
        
        override var icon: NSImage { return original?.icon ?? NSImage(named: .homeName)! }
        
        override var persistentID: String { return (original?.persistentID ?? "") + ".alias" }
        
        override var isValid: Bool { return original != nil }
    }
    
    class IndexItem: Preloaded {
        init(master: MasterItem) {
            super.init(items: [
                MasterAlias(master),
                ArtistsItem(),
                GenresItem(),
                AlbumsItem(),
            ])
        }
        
        override var title: String { return "Index" }
        
        override var icon: NSImage { return NSImage(named: .advancedInfoName)! }
        
        override var persistentID: String { return "Index" }
    }
    
    class ArtistsItem: PlaylistController.Item {
        override var title: String { return "Artists" }
        
        override var icon: NSImage { return NSImage(named: .artistName)! }
        
        override var persistentID: String { return "Artists" }
    }
    
    class GenresItem: PlaylistController.Item {
        override var title: String { return "Genres" }
        
        override var icon: NSImage { return NSImage(named: .genreName)! }
        
        override var persistentID: String { return "Genres" }
    }
    
    class AlbumsItem: PlaylistController.Item {
        override var title: String { return "Albums" }
        
        override var icon: NSImage { return NSImage(named: .albumName)! }
        
        override var persistentID: String { return "Albums" }
    }
}
