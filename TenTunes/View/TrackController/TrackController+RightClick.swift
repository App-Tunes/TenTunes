//
//  File.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

extension TrackController: NSMenuDelegate {
    var menuTracks: [Track] {
        return _tableView.clickedRows.compactMap { history.track(at: $0) }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu !== _showInPlaylistSubmenu.submenu else {
            menu.removeAllItems()
            for case let playlist as Playlist in menuTracks.first!.containingPlaylists {
                let item = NSMenuItem(title: playlist.name, action: #selector(menuShowInPlaylist), keyEquivalent: "")
                item.target = self
                item.representedObject = playlist
                menu.addItem(item)
            }
            
            return
        }
        
        if menuTracks.count < 1 {
            menu.cancelTrackingWithoutAnimation()
        }
        
        _showInPlaylistSubmenu.isHidden = menuTracks.count != 1
        
        _moveToMediaDirectory.isHidden = menuTracks.noneMatch { !$0.usesMediaDirectory && $0.url != nil }
        
        let someNeedAnalysis = menuTracks.anyMatch { $0.url != nil }
        _analyzeSubmenu.isVisible = someNeedAnalysis && menuTracks.anyMatch { $0.analysis != nil } && menuTracks.anyMatch { $0.analysis == nil }
        menu.item(withAction: #selector(menuAnalyze))?.isVisible = someNeedAnalysis && _analyzeSubmenu.isHidden

        if isQueue {
            let deleteItem = menu.item(withAction: #selector(removeTrack))
            deleteItem?.isHidden = false
            deleteItem?.title = "Remove from Queue"
        }
        else {
            menu.item(withAction: #selector(removeTrack))?.isHidden = Library.shared.isPlaylist(playlist: history.playlist)
        }
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Probably the main Application menu
        if menuItem.target !== self {
            return validateUserInterfaceItem(menuItem)
        }
        
        // Right Click Menu
        if menuItem.action == #selector(removeTrack) { return isQueue || Library.shared.isEditable(playlist: history.playlist) }
        if menuItem.action == #selector(menuShowInFinder) { return menuTracks.count == 1 && menuTracks.first!.url != nil }
        
        return true
    }
    
    @IBAction func menuPlay(_ sender: Any) {
        self.doubleClick(sender)
    }
    
    @IBAction func menuPlayNext(_ sender: Any) {
        let row = self._tableView.clickedRow
        
        if let playTrackNext = playTrackNext {
            if history.track(at: row) != nil {
                playTrackNext(row)
            }
        }
    }
    
    @IBAction func menuShowTrackInfo(_ sender: Any?) {
        showTrackInfo(of: _tableView.clickedRows, nextTo: _tableView.rowView(atRow: _tableView.clickedRow, makeIfNecessary: false))
    }
    
    @IBAction func menuShowInPlaylist(_ sender: Any) {
        guard let item = sender as? NSMenuItem, let playlist = item.representedObject as? Playlist else {
            return
        }
        
        ViewController.shared.playlistController.select(playlist: playlist)
        // TODO select track
    }

    @IBAction func menuShowInFinder(_ sender: Any) {
        let row = self._tableView.clickedRow
        let track = history.track(at: row)!
        if let url = track.url {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    
    @IBAction func manageByMoving(_ sender: Any) {
        // TODO If too many, do in background
        for track in menuTracks {
            track.usesMediaDirectory = true
        }
        
        Library.shared.mediaLocation.updateLocations(of: menuTracks)
    }
    
    @IBAction func manageByCopying(_ sender: Any) {
        for track in menuTracks {
            track.usesMediaDirectory = true
        }
        
        Library.shared.mediaLocation.updateLocations(of: menuTracks, copy: true)
    }
    
    @IBAction func menuAnalyze(_ sender: Any) {
        ViewController.shared.analysisToDo = ViewController.shared.analysisToDo.union(menuTracks)
    }
    
    @IBAction func menuAnalyzeWhereMissing(_ sender: Any) {
        let missing = menuTracks.filter { $0.analysis == nil }
        ViewController.shared.analysisToDo = ViewController.shared.analysisToDo.union(missing)
    }
    
    @IBAction func removeTrack(_ sender: Any) {
        remove(indices: _tableView.clickedRows)
    }
    
    @IBAction func deleteTrack(_ sender: Any) {
        Library.shared.viewContext.delete(all: menuTracks)
    }
}
