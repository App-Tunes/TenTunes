//
//  TrackBehavior.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class MenuHijacker: NSViewController, NSMenuDelegate {
    class MenuState {
        weak var source: NSMenu?
        var delegate: NSMenuDelegate?
        var items: [NSMenuItem]
        
        init(from menu: NSMenu) {
            source = menu
            delegate = menu.delegate
            items = menu.items
        }
        
        func apply(to menu: NSMenu) {
            menu.delegate = delegate
            menu.items = items
        }
    }
    
    var backup: MenuState?
    var selfBackup: MenuState?

    func hijack(menu: NSMenu) {
        backup = MenuState(from: menu)
        selfBackup = MenuState(from: baseMenu)

        baseMenu.removeAllItems() // Free items for use
        selfBackup?.apply(to: menu)
        
        (self as NSMenuDelegate).menuNeedsUpdate?(menu)
    }

    func menuDidClose(_ menu: NSMenu) {
        if menu == backup?.source {
            backup?.apply(to: menu)
            selfBackup?.apply(to: baseMenu)
            backup = nil
            selfBackup = nil
        }
        else if backup?.source == nil {
            // Has deallocated sometime between
            backup = nil
            selfBackup = nil
        }
    }
    
    var baseMenu: NSMenu { fatalError() }
}

extension TrackActions {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let tracks = context.tracks
        
        guard menu !== _showInPlaylistSubmenu.submenu else {
            menu.removeAllItems()
            for playlist in Library.shared.playlists(containing: tracks.first!) {
                let item = NSMenuItem(title: playlist.name, action: #selector(menuShowInPlaylist), keyEquivalent: "")
                item.target = self
                item.representedObject = playlist
                menu.addItem(item)
            }
            
            return
        }
        
        guard menu !== _addToPlaylistSubmenu.submenu else {
            menu.removeAllItems()
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
        
        if tracks.count < 1 {
            menu.cancelTrackingWithoutAnimation()
        }
        
        menu.item(withAction: #selector(menuShowInfo))?.title = trackEditorWantsUpdate ? "Show Info" : "Hide Info"
        
        _showInPlaylistSubmenu.isVisible = tracks.count == 1
        if _showInPlaylistSubmenu.isVisible {
            _showInPlaylistSubmenu.isEnabled = !Library.shared.playlists(containing: tracks.first!).isEmpty
        }
        
        menu.item(withAction: #selector(menuShowAuthor(_:)))?.isVisible = tracks.count == 1 && tracks.first!.author != nil
        menu.item(withAction: #selector(menuShowAlbum(_:)))?.isVisible = tracks.count == 1 && tracks.first!.album != nil
        
        _moveToMediaDirectory.isHidden = tracks.noneSatisfy { !$0.usesMediaDirectory && $0.liveURL != nil }
        
        let someNeedAnalysis = tracks.anySatisfy { $0.liveURL != nil }
        _analyzeSubmenu.isVisible = someNeedAnalysis && tracks.anySatisfy { $0.analysisData != nil } && tracks.anySatisfy { $0.analysisData == nil }
        menu.item(withAction: #selector(menuAnalyze))?.isVisible = someNeedAnalysis && _analyzeSubmenu.isHidden
        menu.item(withAction: #selector(menuAnalyzeMetadata))?.isVisible = someNeedAnalysis
        
        menu.item(withAction: #selector(removeFromPlaylist(_:)))?.isVisible = (context.playlist ?=> Library.shared.isPlaylist) ?? false
        menu.item(withAction: #selector(removeFromQueue(_:)))?.isVisible = tracks.anySatisfy(player.history.tracks.contains)
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // Right Click Menu
        if menuItem.action == #selector(removeFromPlaylist(_:)) {
            return (context.playlist as? ModifiablePlaylist)?.supports(action: .delete) ?? false
        }
        
        if menuItem.action == #selector(menuShowInFinder) {
            return context.tracks.onlyElement?.liveURL != nil
        }
        
        return true
    }
}

class TrackActions: MenuHijacker {
    enum Context {
        case playlist(at: [Int], in: PlayHistory)
        case none(tracks: [Track])

        var historyIndex: ([Int], PlayHistory)? {
            switch self {
            case .playlist(let indices, let history):
                return (indices, history)
            default:
                return nil
            }
        }
        
        var tracks: [Track] {
            if let (idx, history) = historyIndex {
                return idx.compactMap(history.track)
            }
            
            switch self {
            case .none(let tracks):
                return tracks
            default:
                fatalError()
            }
        }
        
        var playlist: AnyPlaylist? {
            if let (_, history) = historyIndex {
                return history.playlist
            }
            
            return nil
        }
    }
    
    var context: Context!

    @IBOutlet var _menu: NSMenu!
    @IBOutlet var _moveToMediaDirectory: NSMenuItem!
    @IBOutlet var _analyzeSubmenu: NSMenuItem!
    @IBOutlet var _showInPlaylistSubmenu: NSMenuItem!
    @IBOutlet var _addToPlaylistSubmenu: NSMenuItem!
    
    override var baseMenu: NSMenu { return _menu }
    
    // TODO Try to make less omniscient?
    var viewController: ViewController {
        return ViewController.shared
    }
    
    var trackEditor: TrackEditor {
        return viewController.trackController.trackEditor
    }
    
    var trackEditorGuard: MultiplicityGuardView {
        return viewController.trackController!.trackEditorGuard
    }
    
    var player: Player {
        return viewController.player
    }
    
    var trackEditorWantsUpdate: Bool {
        return trackEditorGuard.isHidden || context.tracks != trackEditor.tracks
    }
    
    var tasker: QueueTasker {
        return viewController.tasker
    }

    static func create(_ context: Context) -> TrackActions {
        let actions = TrackActions(nibName: .init("TrackActions"), bundle: nil)
        actions.loadView()
        actions.context = context
        return actions
    }
    
    @IBAction func doubleClick(_ sender: Any) {
        menuPlay(sender)
    }
    
    @IBAction func menuPlay(_ sender: Any) {
        guard let (idx, history) = context.historyIndex else {
            // No history in context, let's just play directory
            let history = PlayHistory(playlist: PlaylistEmpty())
            history.enqueue(tracks: context.tracks, at: .start)
            player.play(at: 0, in: history)
            return
        }

        // TODO Support for multiple at once by enqueueing
        let first = idx.first!

        if player.history === history {
            // Just move to the right spot
            player.play(moved: first - history.playingIndex)
        }
        else {
            // Let's set the history
            player.play(at: first, in: history)
        }
    }
    
    @IBAction func menuPlayNext(_ sender: Any) {
        //if let (idx, history) = context.historyIndex, player.history === history {
        //    // TODO Move to front instead of adding
        //    return
        //}
        
        player.enqueue(tracks: context.tracks, at: .start)
    }
    
    @IBAction func menuPlayLater(_ sender: Any) {
        //if let (idx, history) = context.historyIndex, player.history === history {
        //    // TODO Move to front instead of adding
        //    return
        //}
        
        player.enqueue(tracks: context.tracks, at: .end)
    }
    
    @IBAction func menuShowInfo(_ sender: Any) {
        guard trackEditorWantsUpdate else {
            trackEditorGuard.isHidden = true
            return
        }
        
        if viewController._trackGuardView.contentView != viewController.trackController {
            // Show the track controller first
            viewController.playlistController.select(.master)
        }
        
        trackEditorGuard.show(elements: context.tracks)
        trackEditorGuard.isHidden = false
    }
    
    @IBAction func menuShowInPlaylist(_ sender: Any) {
        guard let item = sender as? NSMenuItem, let playlist = item.representedObject as? Playlist else {
            return
        }
        
        viewController.playlistController.select(playlist: playlist)
        viewController.trackController.select(tracks: context.tracks)
    }
    
    @IBAction func menuAddToPlaylist(_ sender: Any) {
        guard let item = sender as? NSMenuItem, let playlist = item.representedObject as? PlaylistManual else {
            return
        }
        
        playlist.addTracks(context.tracks)
    }
    
    @IBAction func menuShowAuthor(_ sender: Any) {
        guard let track = context.tracks.onlyElement else {
            return
        }
        
        ViewController.shared.playlistController.selectLibrary(self)
        ViewController.shared.trackController?.show(tokens: track.authors.map(SmartPlaylistRules.Token.Author.init))
    }
    
    @IBAction func menuShowAlbum(_ sender: Any) {
        guard let track = context.tracks.onlyElement else {
            return
        }
    
        viewController.playlistController.selectLibrary(self)
        viewController.trackController?.show(tokens: [
            .InAlbum(album: track.rAlbum!)
        ])
    }
    
    @IBAction func menuShowInFinder(_ sender: Any) {
        guard let track = context.tracks.onlyElement else {
            return
        }

        guard let url = track.liveURL else {
            return
        }
        
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    @IBAction func manageByMoving(_ sender: Any) {
        for track in context.tracks {
            tasker.enqueue(task: MoveTrackToMediaLocation(track: track, copy: false))
        }
    }
    
    @IBAction func manageByCopying(_ sender: Any) {
        for track in context.tracks {
            tasker.enqueue(task: MoveTrackToMediaLocation(track: track, copy: true))
        }
    }
    
    @IBAction func menuAnalyze(_ sender: Any) {
        for track in context.tracks {
            tasker.enqueue(task: AnalyzeTrack(track: track, read: false))
        }
    }
    
    @IBAction func menuAnalyzeWhereMissing(_ sender: Any) {
        let missing = context.tracks.filter { $0.analysisData == nil }
        for track in missing {
            tasker.enqueue(task: AnalyzeTrack(track: track, read: false))
        }
    }
    
    @IBAction func menuAnalyzeMetadata(_ sender: Any) {
        for track in context.tracks {
            tasker.enqueue(task: AnalyzeTrack(track: track, read: false, analyzeFlags: [.speed, .key]))
        }
    }
    
    @IBAction func menuRefetchMetadata(_ sender: Any) {
        for track in context.tracks {
            track.metadataFetchDate = nil
        }
    }
    
    @IBAction func removeFromPlaylist(_ sender: Any) {
        guard let playlist = context.playlist as? ModifiablePlaylist else {
            return
        }
        
        guard playlist.confirm(action: .delete) else {
            return
        }
        
        playlist.removeTracks(context.tracks)
    }

    @IBAction func removeFromQueue(_ sender: Any) {
        if let (idx, history) = context.historyIndex, player.history === history {
            // Remove specific indices
            history.remove(indices: idx)
            return
        }
        
        // Just remove the tracks at all
        //let tracksBefore = history.tracks
        player.history.remove(indices: context.tracks.compactMap(player.history.indexOf))
        // TODO
        //_tableView.animateDifference(from: tracksBefore, to: history.tracks)
        return
    }

    @IBAction func deleteTrack(_ sender: Any) {
        let tracks = context.tracks
        
        let message = "Are you sure you want to delete \(AppDelegate.defaults.describe(trackCount: tracks.count)) from the library? Tracks may be moved to trash if they are located in the media directory."
        if NSAlert.confirm(action: "Delete Tracks", text: message) {
            Library.shared.viewContext.delete(all: tracks)
        }
    }
}
