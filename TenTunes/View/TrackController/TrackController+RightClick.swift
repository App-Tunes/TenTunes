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
        
        menu.item(withAction: #selector(menuPlay))?.isVisible = playTrack != nil
        
        _showInPlaylistSubmenu.isHidden = menuTracks.count != 1
        
        _moveToMediaDirectory.isHidden = menuTracks.noneMatch { !$0.usesMediaDirectory && $0.url != nil }
        
        let someNeedAnalysis = menuTracks.anyMatch { $0.url != nil }
        _analyzeSubmenu.isVisible = someNeedAnalysis && menuTracks.anyMatch { $0.analysisData != nil } && menuTracks.anyMatch { $0.analysisData == nil }
        menu.item(withAction: #selector(menuAnalyze))?.isVisible = someNeedAnalysis && _analyzeSubmenu.isHidden

        let deleteItem = menu.item(withAction: #selector(removeTrack))
        if mode == .queue {
            deleteItem?.isHidden = false
            deleteItem?.title = "Remove from Queue"
        }
        else if mode == .tracksList {
            deleteItem?.isHidden = Library.shared.isPlaylist(playlist: history.playlist)
        }
        else {
            deleteItem?.isHidden = true
        }
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Probably the main Application menu
        if menuItem.target !== self {
            return validateUserInterfaceItem(menuItem)
        }
        
        // Right Click Menu
        if menuItem.action == #selector(removeTrack) { return mode == .queue || (mode == .tracksList && Library.shared.isEditable(playlist: history.playlist)) }
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
        for track in menuTracks {
            ViewController.shared.tasker.enqueue(task: MoveTrackToMediaLocation(track: track, copy: false))
        }
    }
    
    @IBAction func manageByCopying(_ sender: Any) {
        for track in menuTracks {
            ViewController.shared.tasker.enqueue(task: MoveTrackToMediaLocation(track: track, copy: true))
        }
    }
    
    @IBAction func menuAnalyze(_ sender: Any) {
        for track in menuTracks {
            ViewController.shared.tasker.enqueue(task: AnalyzeTrack(track: track, read: false))
        }
    }
    
    @IBAction func menuAnalyzeWhereMissing(_ sender: Any) {
        let missing = menuTracks.filter { $0.analysisData == nil }
        for track in missing {
            ViewController.shared.tasker.enqueue(task: AnalyzeTrack(track: track, read: false))
        }
    }
    
    @IBAction func removeTrack(_ sender: Any) {
        remove(indices: _tableView.clickedRows)
    }
    
    @IBAction func deleteTrack(_ sender: Any) {
        let tracks = menuTracks
        let message = "Are you sure you want to delete \(tracks.count) track\(tracks.count > 1 ? "s" : "") from the library? Tracks may be moved to trash if they are located in the media directory."
        if NSAlert.confirm(action: "Delete Tracks", text: message) {
            Library.shared.viewContext.delete(all: tracks)
        }
    }
}
