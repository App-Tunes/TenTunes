//
//  PlaylistController+RightClick.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

extension PlaylistController: NSMenuDelegate {
    var menuPlaylists: [Playlist] {
        return _outlineView.clickedRows.compactMap { _outlineView.item(atRow: $0) as? Playlist }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        if menuPlaylists.count < 1 {
            menu.cancelTrackingWithoutAnimation()
        }
        
        menu.item(withAction: #selector(deletePlaylist(_:)))?.isVisible = menuPlaylists.map(Library.shared.isPlaylist).allMatch { $0 }

        menu.item(withAction: #selector(untanglePlaylist(_:)))?.isVisible = (menuPlaylists.uniqueElement ?=> self.isUntangleable) ?? false
        menu.item(withAction: #selector(sortPlaylistChildren(_:)))?.isVisible = (menuPlaylists.uniqueElement is PlaylistFolder) ?? false
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Probably the main Application menu
        if menuItem.target !== self {
            return validateUserInterfaceItem(menuItem)
        }
        
        return true
    }
    
    @IBAction func duplicatePlaylist(_ sender: Any) {
        for playlist in menuPlaylists {
            let copy = playlist.duplicate()
            let idx = playlist.parent!.children.index(of: playlist)
            
            playlist.parent!.addPlaylist(copy, above: idx)
        }
        
        try! Library.shared.viewContext.save()
    }
    
    @IBAction func deletePlaylist(_ sender: Any) {
        delete(indices: _outlineView.clickedRows)
    }
    
    @IBAction func untanglePlaylist(_ sender: Any) {
        guard let folder = menuPlaylists.uniqueElement as? PlaylistFolder else {
            return
        }
        
        untangle(playlist: folder)
        try! Library.shared.viewContext.save()
    }
    
    func isUntangleable(playlist: Playlist) -> Bool {
        guard let folder = menuPlaylists.uniqueElement as? PlaylistFolder else {
            return false
        }
        
        return folder.childrenList.count > 1 && untangle(playlist: folder, dryRun: true)
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
            if strings.allMatch({
                let split = $0.split(separator: character)
                return split.count == 2 && split.allMatch { $0.count > 0 } }) {
                
                return character
            }
        }
        
        return nil
    }
    
    @IBAction func sortPlaylistChildren(_ sender: Any) {
        let playlist = menuPlaylists.uniqueElement as! PlaylistFolder
        playlist.childrenList.sort { $0.name < $1.name }
    }
}
