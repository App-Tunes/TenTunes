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
    
    var trackEditorWantsUpdate: Bool {
        return menuTracks != trackEditor.tracks || trackEditorGuard.isHidden
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu !== _showInPlaylistSubmenu.submenu else {
            menu.removeAllItems()
            for playlist in Library.shared.playlists(containing: menuTracks.first!) {
                let item = NSMenuItem(title: playlist.name, action: #selector(menuShowInPlaylist), keyEquivalent: "")
                item.target = self
                item.representedObject = playlist
                menu.addItem(item)
            }
            
            return
        }

        guard menu !== _addToPlaylistSubmenu.submenu else {
            menu.removeAllItems()
            let tracks = menuTracks
            for playlist in Library.shared.allPlaylists().of(type: PlaylistManual.self)
                .filter({ !Library.shared.isTag(playlist: $0) })
                .filter({ playlist in tracks.anySatisfy { !playlist.tracksList.contains($0) } }) {
                    
                let item = NSMenuItem(title: playlist.name, action: #selector(menuAddToPlaylist), keyEquivalent: "")
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

        menu.item(withAction: #selector(menuShowInfo))?.title = trackEditorWantsUpdate ? "Show Info" : "Hide Info"

        _showInPlaylistSubmenu.isVisible = menuTracks.count == 1
        if _showInPlaylistSubmenu.isVisible {
            _showInPlaylistSubmenu.isEnabled = !Library.shared.playlists(containing: menuTracks.first!).isEmpty 
        }
        
        menu.item(withAction: #selector(menuShowAuthor(_:)))?.isVisible = menuTracks.count == 1 && menuTracks.first!.author != nil
        menu.item(withAction: #selector(menuShowAlbum(_:)))?.isVisible = menuTracks.count == 1 && menuTracks.first!.album != nil

        _moveToMediaDirectory.isHidden = menuTracks.noneSatisfy { !$0.usesMediaDirectory && $0.liveURL != nil }
        
        let someNeedAnalysis = menuTracks.anySatisfy { $0.liveURL != nil }
        _analyzeSubmenu.isVisible = someNeedAnalysis && menuTracks.anySatisfy { $0.analysisData != nil } && menuTracks.anySatisfy { $0.analysisData == nil }
        menu.item(withAction: #selector(menuAnalyze))?.isVisible = someNeedAnalysis && _analyzeSubmenu.isHidden
        menu.item(withAction: #selector(menuAnalyzeMetadata))?.isVisible = someNeedAnalysis

        let deleteItem = menu.item(withAction: #selector(removeTrack))
        switch mode {
        case .queue:
            deleteItem?.isHidden = false
            deleteItem?.title = "Remove from Queue"
        case .tracksList:
            deleteItem?.isVisible = Library.shared.isPlaylist(playlist: history.playlist)
        case .title:
            deleteItem?.isHidden = true
        }
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Probably the main Application menu
        if menuItem.target !== self {
            return validateUserInterfaceItem(menuItem)
        }
        
        // Right Click Menu
        if menuItem.action == #selector(removeTrack) {
            return mode == .queue || (mode == .tracksList && ((history.playlist as? ModifiablePlaylist)?.supports(action: .delete) ?? false))
        }
        
        if menuItem.action == #selector(menuShowInFinder) {
            return menuTracks.count == 1 && menuTracks.first!.liveURL != nil
        }

        return true
    }
    
    @IBAction func menuPlay(_ sender: Any) {
        self.doubleClick(sender)
    }
    
    @IBAction func menuPlayNext(_ sender: Any) {
        let row = self._tableView.clickedRow
        
        if history.track(at: row) != nil {
            playTrackNext?(row)
        }
    }
    
    @IBAction func menuPlayLater(_ sender: Any) {
        let row = self._tableView.clickedRow
        
        if history.track(at: row) != nil {
            playTrackLater?(row)
        }
    }
    
    @IBAction func menuShowInfo(_ sender: Any) {
        guard trackEditorWantsUpdate else {
            trackEditorGuard.isHidden = true
            return
        }
        
        trackEditorGuard.show(elements: menuTracks)
        trackEditorGuard.isHidden = false
    }
    
    @IBAction func menuShowInPlaylist(_ sender: Any) {
        guard let item = sender as? NSMenuItem, let playlist = item.representedObject as? Playlist else {
            return
        }
        
        ViewController.shared.playlistController.select(playlist: playlist)
        // TODO select track
    }
    
    @IBAction func menuAddToPlaylist(_ sender: Any) {
        guard let item = sender as? NSMenuItem, let playlist = item.representedObject as? PlaylistManual else {
            return
        }
        
        playlist.addTracks(menuTracks)
    }
    
    @IBAction func menuShowAuthor(_ sender: Any) {
        ViewController.shared.playlistController.selectLibrary(self)
        let track = menuTracks.first!

        ViewController.shared.trackController.filterBar.open()
        ViewController.shared.trackController.filterController.rules = SmartPlaylistRules(tokens: track.authors.map(SmartPlaylistRules.Token.Author.init))
    }

    @IBAction func menuShowAlbum(_ sender: Any) {
        ViewController.shared.playlistController.selectLibrary(self)
        let track = menuTracks.first!
        
        let trackController = ViewController.shared.trackController!
        trackController.filterBar.open()
        trackController.filterController.rules = SmartPlaylistRules(tokens: [.InAlbum(album: track.rAlbum!)])
    }

    @IBAction func menuShowInFinder(_ sender: Any) {
        let row = self._tableView.clickedRow
        let track = history.track(at: row)!
        if let url = track.liveURL {
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
    
    @IBAction func menuAnalyzeMetadata(_ sender: Any) {
        for track in menuTracks {
            ViewController.shared.tasker.enqueue(task: AnalyzeTrack(track: track, read: false, analyzeFlags: [.speed, .key]))
        }
    }
    
    @IBAction func menuRefetchMetadata(_ sender: Any) {
        for track in menuTracks {
            track.metadataFetchDate = nil
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
