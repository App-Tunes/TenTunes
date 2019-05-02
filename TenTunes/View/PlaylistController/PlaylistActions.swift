//
//  PlaylistActions.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class PlaylistActions: NSViewController, NSMenuDelegate, NSMenuItemValidation {
    enum Context {
        case visible(playlists: [Playlist])
        case invisible(playlists: [Playlist])
        
        var playlists: [Playlist] {
            switch self {
            case .visible(let playlists):
                return playlists
            case .invisible(let playlists):
                return playlists
            }
        }
        
        var isVisible: Bool {
            switch self {
            case .visible(_):
                return true
            case .invisible(_):
                return false
            }
        }
    }
    
    var context: Context!
    
    @IBOutlet var _playlistMenu: NSMenu!
    @IBOutlet var _emptyMenu: NSMenu!
    
    // TODO Try to make less omniscient?
    var viewController: ViewController {
        return ViewController.shared
    }
    
    var player: Player {
        return viewController.player
    }
    
    static func create(_ context: Context) -> PlaylistActions? {
        let actions = PlaylistActions(nibName: .init("PlaylistActions"), bundle: nil)
        actions.loadView()
        actions.context = context
        return actions
    }
    
    func menu() -> NSMenu {
        return context.playlists.isEmpty
            ? _emptyMenu : _playlistMenu
    }
    
    static func insertionPosition(whenSelecting playlists: [Playlist], allowInside: Bool = true) -> (PlaylistFolder, Int?) {
        let defaultPos: (PlaylistFolder, Int?) = (Library.shared[PlaylistRole.playlists], nil)
        
        if allowInside, let folder = playlists.onlyElement as? PlaylistFolder, !folder.automatesChildren {
            // Add inside, as last
            return (folder, nil)
        }

        // TODO What do if Placeholder?
        
        if let playlist = playlists.onlyElement, let (parent, idx) = Library.shared.position(of: playlist), !parent.automatesChildren {
            // Add below the playlist
            return (parent, idx + 1)
        }

        if let parent = (playlists.map { $0.parent! }).uniqueElement, !parent.automatesChildren {
            // Add to the parent
            return (parent, nil)
        }

        return defaultPos
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        let playlists = context.playlists
        
        guard playlists.count >= 1 else {
            menu.cancelTrackingWithoutAnimation()
            return
        }
        
        let isVisible = context.isVisible
        // Set all items to the "default value"
        for item in menu.items.dropFirst() {
            item.isVisible = isVisible
        }

        guard isVisible else {
            return
        }
        
        menu.item(withAction: #selector(deletePlaylist(_:)))?.isVisible = playlists.map(Library.shared.isPlaylist).allSatisfy { $0 }
        
        menu.item(withAction: #selector(untanglePlaylist(_:)))?.isVisible = (playlists.uniqueElement ?=> self.isUntangleable) ?? false
        menu.item(withAction: #selector(sortPlaylistChildren(_:)))?.isVisible = !((playlists.uniqueElement as? PlaylistFolder)?.automatesChildren ?? true)
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
    
    func insertionPosition(allowInside: Bool = true) -> (PlaylistFolder, Int?) {
        return PlaylistActions.insertionPosition(whenSelecting: context.playlists, allowInside: true)
    }
        
    @IBAction func menuPlay(_ sender: Any) {
        guard let playlist = context.playlists.onlyElement else {
            return
        }
        
        // TODO If the playlist is already selected (-> track controller has a history)
        // use that history instead since it might have sort
        player.play(at: nil, in: PlayHistory(playlist: playlist))
    }
    
    @IBAction func duplicatePlaylist(_ sender: Any) {
        for playlist in context.playlists {
            let copy = playlist.duplicate()
            
            // Use this so we get a legal insertion position no matter what
            let (parent, idx) = PlaylistActions.insertionPosition(whenSelecting: [playlist], allowInside: false)
            parent.addPlaylist(copy, above: idx)
        }
        
        try! Library.shared.viewContext.save()
    }
    
    func delete(confirm: Bool = true) {
        let playlists = context.playlists
        let message = "Are you sure you want to delete \(Playlist.describe(count: playlists.count))?"
        guard !confirm || NSAlert.ensure(intent: playlists.allSatisfy { $0.isTrivial }, action: "Delete Playlists", text: message) else {
            return
        }
        
        guard playlists.allSatisfy({ Library.shared.isPlaylist(playlist: $0) }) else {
            fatalError("Trying to delete undeletable playlists!")
        }
        
        Library.shared.viewContext.delete(all: playlists)
        try! Library.shared.viewContext.save()
    }

    @IBAction func deletePlaylist(_ sender: Any) {
        delete(confirm: true)
    }
    
    @IBAction func untanglePlaylist(_ sender: Any) {
        guard let folder = context.playlists.onlyElement as? PlaylistFolder else {
            return
        }
        
        untangle(playlist: folder)
        try! Library.shared.viewContext.save()
    }
    
    func isUntangleable(playlist: Playlist) -> Bool {
        guard let folder = context.playlists.onlyElement as? PlaylistFolder else {
            return false
        }
        
        return folder.childrenList.count > 1 && untangle(playlist: folder, dryRun: true)
    }
    
    func insert(playlist: Playlist) {
        let (parent, idx) = insertionPosition(allowInside: true)
        parent.addPlaylist(playlist, above: idx)
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
        //let selected = context.playlists
        let group = PlaylistFolder(context: Library.shared.viewContext)
        insert(playlist: group)
        
        // TODO Put selected items in group if we can
        //if selected.count > 1, selected.map({ $0.1.parent }).uniqueElement != nil {
        //    for (_, playlist) in selected {
        //        group.addToChildren(playlist)
        //    }
        //}
        
        try! Library.shared.viewContext.save()
    }
    
    @IBAction func createCartesianPlaylist(_ sender: Any) {
        insert(playlist: PlaylistCartesian(context: Library.shared.viewContext))
        try! Library.shared.viewContext.save()
    }
    
    class UntangledPlaylist {
        let original: Playlist
        let left: String
        let right: String
        
        init(original: Playlist, left: String, right: String) {
            self.original = original
            self.left = left
            self.right = right
        }
    }
    
    @discardableResult
    func untangle(playlist: PlaylistFolder, dryRun: Bool = false) -> Bool {
        let all = playlist.childrenList
        
        guard let splitChar = findSplitChar(in: all.map { $0.name }) else {
            return false
        }
        
        guard !dryRun else {
            return true
        }
        
        let untangled : [UntangledPlaylist] = all.map {
            let split = $0.name.split(separator: splitChar)
            return UntangledPlaylist(original: $0, left: String(split[0]), right: String(split[1]))
        }
        
        let leftFolder = PlaylistFolder(context: Library.shared.viewContext)
        leftFolder.name = "\(playlist.name) | Left"
        for subName in (untangled.map { $0.left }).uniqueElements {
            let sub = PlaylistManual(context: Library.shared.viewContext)
            sub.name = subName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            for part in untangled where part.left == subName {
                sub.addTracks(part.original.tracksList)
            }
            leftFolder.addToChildren(sub)
        }
        
        playlist.parent!.addToChildren(leftFolder)
        
        let rightFolder = PlaylistFolder(context: Library.shared.viewContext)
        rightFolder.name = "\(playlist.name) | Right"
        for subName in (untangled.map { $0.right }).uniqueElements {
            let sub = PlaylistManual(context: Library.shared.viewContext)
            sub.name = subName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            for part in untangled where part.right == subName {
                sub.addTracks(part.original.tracksList)
            }
            rightFolder.addToChildren(sub)
        }
        
        playlist.parent!.addToChildren(rightFolder)
        
        return true
    }
    
    func findSplitChar(in strings: [String]) -> Character? {
        guard let anchor = strings.first else {
            return nil
        }
        
        for character in anchor {
            if strings.allSatisfy({
                let split = $0.split(separator: character)
                return split.count == 2 && split.allSatisfy { $0.count > 0 } }) {
                
                return character
            }
        }
        
        return nil
    }
    
    @IBAction func sortPlaylistChildren(_ sender: Any) {
        guard let folders = context.playlists as? [PlaylistFolder] else {
            return
        }
        
        for folder in folders {
            folder.childrenList.sort { $0.name < $1.name }
        }
    }
}
