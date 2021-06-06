//
//  TrackBehavior.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class TrackActions: NSViewController, NSMenuDelegate, NSMenuItemValidation {
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

    @IBOutlet var _repairTrack: NSMenuItem!

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

    static func create(_ context: Context) -> TrackActions? {
        guard context.tracks.count > 0 else {
            return nil
        }
        
        let actions = TrackActions(nibName: .init("TrackActions"), bundle: nil)
        actions.loadView()
        actions.context = context
        return actions
    }
    
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
        
        menu.item(withAction: #selector(menuShowInfo))?.title = trackEditorWantsUpdate ? "Edit Info" : "Hide Info"
        
        if tracks.count == 1 {
            _showInPlaylistSubmenu.isVisible = true
            if _showInPlaylistSubmenu.isVisible {
                _showInPlaylistSubmenu.isEnabled = !Library.shared.playlists(containing: tracks.first!).isEmpty
            }
            
            _repairTrack.isVisible = true
        }
        else {
            _showInPlaylistSubmenu.isVisible = false
            _repairTrack.isVisible = false
        }
        
        menu.item(withAction: #selector(menuShowAuthor(_:)))?.isVisible = tracks.count == 1 && tracks.first!.author != nil
        menu.item(withAction: #selector(menuShowAlbum(_:)))?.isVisible = tracks.count == 1 && tracks.first!.album != nil
        
        _moveToMediaDirectory.isHidden = tracks.noneSatisfy { !$0.usesMediaDirectory && $0.liveURL != nil }
        
        let someNeedAnalysis = tracks.anySatisfy { $0.liveURL != nil }
        _analyzeSubmenu.isVisible = someNeedAnalysis && tracks.anySatisfy { $0.analysisData != nil } && tracks.anySatisfy { $0.analysisData == nil }
        menu.item(withAction: #selector(menuAnalyze))?.isVisible = someNeedAnalysis && _analyzeSubmenu.isHidden
        menu.item(withAction: #selector(menuAnalyzeMetadata))?.isVisible = someNeedAnalysis
        
        menu.item(withAction: #selector(removeFromPlaylist(_:)))?.isVisible = context.playlist.map(Library.shared.isPlaylist) ?? false
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
    
    @IBAction func doubleClick(_ sender: Any) {
        menuPlay(sender)
    }
    
    @IBAction func menuPlay(_ sender: Any) {
        guard let (idx, history) = context.historyIndex else {
            // No history in context, let's just play directory
            let history = PlayHistory(playlist: PlaylistEmpty())
            history.enqueue(tracks: context.tracks, at: .start)
            player.play(at: nil, in: history)
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
        
        if viewController._trackGuardView.contentView != viewController.trackController.view {
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
    
    @IBAction func manageTrack(_ sender: Any) {
        switch AppDelegate.defaults[.fileLocationOnAdd] {
        case .link:
            return
        case .move:
            manageByMoving(sender)
        case .copy:
            manageByCopying(sender)
        }
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

    @discardableResult
    static func askReplacement(for track: Track, confirm: Bool = true) -> Bool {
        let noPathProvided = track.path == nil
        
        let action = noPathProvided
            ? "Invalid File"
            : "Missing File"
        let message = noPathProvided
            ? "There is no file attached to this \(AppDelegate.defaults[.trackWordSingular])."
            : "The \(AppDelegate.defaults[.trackWordSingular]) could not be played since the file could not be found."
        
        let deletableFile: () -> URL? = {
            if track.usesMediaDirectory, let url = track.liveURL, FileManager.default.fileExists(atPath: url.path) {
                return url
            }
            return nil
        }
        
        if deletableFile() != nil {
            if !NSAlert.confirm(action: "File Exists", text: "A file exists for this \(AppDelegate.defaults[.trackWordSingular]). When replacing it, the current file will be deleted.") {
                return false
            }
        }
        
        guard !confirm || NSAlert.confirm(action: action, text: message, confirmTitle: "Choose file", style: .warning) else {
            return false
        }

        let dialogue = Library.Import.dialogue(allowedFiles: .track)
        dialogue.allowsMultipleSelection = false
        dialogue.runModal()
        
        guard let url = dialogue.url else {
            return false
        }
        
        if let url = deletableFile() {
            do {
                try FileManager.default.removeItem(at: url)
            }
            catch let e {
                NSAlert.warning(title: "Failed to delete File", text: e.localizedDescription)
            }
        }
        track.path = url.absoluteString
        track.usesMediaDirectory = false
        
        return true
    }

    @IBAction func repairTrack(_ sender: Any) {
        guard let track = context.tracks.onlyElement else {
            return
        }
        
        Self.askReplacement(for: track, confirm: false)
    }
}
