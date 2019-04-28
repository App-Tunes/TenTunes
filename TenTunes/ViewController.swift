//
//  ViewController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import Foundation

import MediaKeyTap
import AVFoundation
import Defaults

func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

class ViewController: NSViewController {
    static let userInterfaceUpdateNotification = NSNotification.Name("TenTunesInterfaceUpdate")
    static let userInterfaceUpdateDuration = CMTime(seconds: 1.0 / 10.0, preferredTimescale: 1000)

    static var shared: ViewController!
    
    @IBOutlet var _coverImage: NSImageView!
    var coverImageObserver: DefaultsObservation?

    @IBOutlet var _playLeftConstraint: NSLayoutConstraint!
    @IBOutlet var _play: NSButton!
    @IBOutlet var _stop: NSButton!
    @IBOutlet var _previous: NSButton!
    @IBOutlet var _next: NSButton!
    
    @IBOutlet var _waveformView: WaveformView!
    
    @IBOutlet var _shuffle: NSButton!
    @IBOutlet var _repeat: SpinningButton!
    @IBOutlet var _find: NSButton!
    @IBOutlet var _taskRightConstraint: NSLayoutConstraint!
    
    @IBOutlet var _timePlayed: NSTextField!
    @IBOutlet var _timeLeft: NSTextField!
    
    @IBOutlet var _playlistView: NSView!
    @IBOutlet var _trackView: NSView!
    @IBOutlet var _trackGuardView: MultiplicityGuardView!
    @IBOutlet var _playingTrackView: NSView!
    @IBOutlet var _splitView: NSSplitView!
    
    @IBOutlet var _queueButton: NSButton!
    var queuePopover: NSPopover!
    var taskPopover: NSPopover!

    var backgroundTimer: Timer!
    
    @objc let player: Player = Player()
    var observerIsPlaying: NSKeyValueObservation?
    var observerPlaying: NSKeyValueObservation?
    var observerCoverImage: NSKeyValueObservation?

    var runningTasks: [Task] = []
    var taskers: [Tasker] = []
    var tasker = QueueTasker()
    var _workerSemaphore = DispatchSemaphore(value: 3)
    @IBOutlet var _taskButton: SpinningButton!
    
    var mediaKeyTap: MediaKeyTap?
    
    var playlistController: PlaylistController!
    var playingTrackController: TrackController!
    var queueController: TrackController!

    var trackController: TrackController!
    var categoryController: CategoryController!

    var taskViewController: TaskViewController!
    
    override func viewDidLoad() {        
        trackController = TrackController(nibName: .init("TrackController"), bundle: nil)
        
        categoryController = CategoryController(nibName: .init("CategoryController"), bundle: nil)
        categoryController.loadView()
        
        _trackGuardView.contentView = trackController.view
        _trackGuardView.delegate = self
        
        playingTrackController = TrackController(nibName: .init("TrackController"), bundle: nil)
        playingTrackController.view.frame = _playingTrackView.frame
        _playingTrackView.setFullSizeContent(playingTrackController.view)
        playingTrackController.titleify()
        
        playlistController = PlaylistController(nibName: .init("PlaylistController"), bundle: nil)
        playlistController.view.frame = _playlistView.frame
        _splitView.replaceSubview(_playlistView, with: playlistController.view)
        
        queueController = TrackController(nibName: .init("TrackController"), bundle: nil)
        
        taskViewController = TaskViewController(nibName: .init("TaskViewController"), bundle: nil)
        
        ViewController.shared = self
        
        player.delegate = self
        player.start()
        player.history = queueController.history // Empty but != nil
        
        playlistController.delegate = self
        let masterItem = PlaylistController.Item.MasterItem(playlist: Library.shared[PlaylistRole.library])
        masterItem.add(items: [
            PlaylistController.Item.IndexItem(master: masterItem),
            playlistController.cache.categoryPlaylistItem(Library.shared[PlaylistRole.tags]),
            playlistController.cache.categoryPlaylistItem(Library.shared[PlaylistRole.playlists]),
        ])
        playlistController.masterItem = masterItem
        playlistController.defaultPlaylist = Library.shared[PlaylistRole.playlists]
        
        _trackGuardView.present(elements: [playlistController.masterItem!])
        
        _queueButton.wantsLayer = true
        _queueButton.layer!.borderWidth = 0.8
        _queueButton.layer!.borderColor = NSColor(white: 0.8, alpha: 0.1).cgColor
        _queueButton.layer!.backgroundColor = NSColor(white: 0.08, alpha: 0.2).cgColor
        _queueButton.layer!.cornerRadius = 6
        
        queuePopover = NSPopover()
        queuePopover.delegate = self
        queuePopover.contentViewController = queueController
        queuePopover.animates = true
        queuePopover.behavior = .transient
        
        taskPopover = NSPopover()
        taskPopover.contentViewController = taskViewController
        taskPopover.animates = true
        taskPopover.behavior = .transient
        
        _waveformView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateTimesHidden), name: NSView.frameDidChangeNotification, object: _waveformView)
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.keyDown(with: $0)
        }
        
        coverImageObserver = UserDefaults.swifty.observe(.titleBarStylization, options: [.initial, .new]) { change in
            self._coverImage.alphaValue = CGFloat(change.newValue)
        }
        
        mediaKeyTap = MediaKeyTap(delegate: self)
        mediaKeyTap?.start()
        
        taskers.append(AnalyzeCurrentTrack())
        taskers.append(CurrentPlaylistUpdater())
        startBackgroundTasks()
        
        playerChangedTrack(player)
        observerPlaying = player.observe(\.playing) { [unowned self] player, _ in
            self.playerChangedTrack(player)
        }
        observerIsPlaying = player.observe(\.isPlaying) { [unowned self] player, _ in
            self._play.image = player.isPlaying ? #imageLiteral(resourceName: "pause") : #imageLiteral(resourceName: "play")
        }
        observerCoverImage = player.observe(\Player.playing?.artworkPreview) { [unowned self] player, _ in
            self._coverImage.transitionWithImage(image: player.playing?.artworkPreview)
        }
    }
    
    func keyDown(with event: NSEvent) -> NSEvent? {
        guard view.window?.isKeyWindow ?? false else {
            return event
        }
        let keyString = event.charactersIgnoringModifiers
        
        if keyString == " ", trackController._tableView.window?.firstResponder is NSTableView {
            self._play.performClick(self) // Grab the spaces from the tables since it takes forever for those
        } 
        else {
            return event
        }
        
        return nil
    }
    
    @IBAction func play(_ sender: Any) {
        guard player.playing != nil else {
            if trackController.selectedTrack != nil {
                player.play(at: trackController._tableView.selectedRow, in: trackController.history)
            }
            else {
                player.play(moved: 0)
            }
            
            return
        }

        player.togglePlay()
    }
    
    @IBAction func nextTrack(_ sender: Any) {
        player.play(moved: 1)
    }
    
    @IBAction func previousTrack(_ sender: Any) {
        player.play(moved: -1)
    }
        
    @IBAction func waveformViewClicked(_ sender: Any) {
        if let position = self._waveformView.location {
            self.player.setPosition(position)
        }
    }
    
    @IBAction func toggleShuffle(_ sender: Any) {
        player.shuffle = !player.shuffle
        _shuffle.state = player.shuffle ? .on : .off
    }
    
    @IBAction func toggleRepeat(_ sender: Any) {
        player.repeat = !player.repeat
        _repeat.state = player.repeat ? .on : .off
    }
    
    @IBAction func showQueue(_ sender: Any) {
        guard !queuePopover.isShown else {
            queuePopover.close()
            return
        }
        
        let target = playingTrackController.view
        
        // TODO Disable button if history is empty
        let history = player.history
        
        if !queueController.isViewLoaded {
            queueController.loadView()
            queueController.queueify()
        }
        
        queueController.history = history
        queueController._tableView?.reloadData() // If it didn't change it doesn't reload automatically
        queuePopover.appearance = view.window!.appearance
        
        // TODO Show a divider on top
        queueController._tableView.scrollRowToTop(history.playingIndex)
        queuePopover.show(relativeTo: target.bounds, of: target, preferredEdge: .maxY)
    }
    
    @IBAction func showTasks(_ sender: Any) {
        let view = sender as! NSView
        
        if !taskViewController.isViewLoaded {
            taskViewController.loadView()
        }
        
        taskViewController.reload(force: true) 
        taskPopover.appearance = view.window!.appearance
        
        taskPopover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
    }
    
    @IBAction func findButtonClicked(_ sender: AnyObject) {
        guard playlistController.history.current != .master || !trackController.filterBar.isOpen else {
            trackController.filterBar.close()
            return
        }
        
        performFindEverywherePanelAction(sender)
    }
    
    @IBAction func updateTimesHidden(_ sender: AnyObject) {
        if player.playing != nil, _waveformView.bounds.height > 30, !player.player.currentTime.isNaN {
            _timePlayed.isHidden = false
            _timeLeft.isHidden = false
        }
        else {
            _timePlayed.isHidden = true
            _timeLeft.isHidden = true
        }
    }
}

extension ViewController: PlaylistControllerDelegate {
    func playlistController(_ controller: PlaylistController, selectionDidChange items: [PlaylistController.Item]) {
        guard !items.isEmpty else {
            return
        }

        _trackGuardView.present(elements: items)
    }
    
    func playlistController(_ controller: PlaylistController, play item: PlaylistController.Item) {
        guard let playlist = item.asAnyPlaylist as? Playlist else {
            return
        }
        
        if (self.trackController.history.playlist as? Playlist) == playlist {
            // Use the existing history because of possible sort etc.
            self.player.play(at: nil, in: self.trackController.history)
        }
        else {
            // Playlist isn't loaded yet in track controller, just play with default sort
            self.player.play(at: nil, in: PlayHistory(playlist: playlist))
        }
    }
}

extension ViewController : MultiplicityGuardDelegate {
    static func asPlaylist(item: PlaylistController.Item) -> AnyPlaylist? {
        return item.asAnyPlaylist
    }
    
    func multiplicityGuard(_ view: MultiplicityGuardView, show elements: [Any]) -> MultiplicityGuardView.ShowAction {
        let items = elements as! [PlaylistController.Item]
        
        guard !items.isEmpty else {
            return .error(text: view.errorSelectionEmpty)
        }
        
        if let playlists = (items.map(ViewController.asPlaylist) as? [AnyPlaylist]) {
            if let playlist = playlists.onlyElement {
                trackController.desired.playlist = playlist
            }
            else {
                trackController.desired.playlist = PlaylistMultiple(playlists: playlists)
            }
            
            view.contentView = trackController.view
        }
        else if items.onlyElement is PlaylistController.Item.AlbumsItem {
            categoryController.categories = Library.shared.allAlbums
                .sorted { $0 < $1 }
                .map(CategoryController.Item.AlbumItem.init)
            
            view.contentView = categoryController.view
        }
        else if items.onlyElement is PlaylistController.Item.ArtistsItem {
            categoryController.categories = Library.shared.allArtists
                .sorted { $0 < $1 }
                .map(CategoryController.Item.ArtistItem.init)
            
            view.contentView = categoryController.view
        }
        else if items.onlyElement is PlaylistController.Item.GenresItem {
            categoryController.categories = Library.shared.allGenres
                .sorted { $0 < $1 }
                .map(CategoryController.Item.GenreItem.init)
            
            view.contentView = categoryController.view
        }
        else {
            return .error(text: "Can't show this set.")
        }
        
        if !AppDelegate.defaults[.keepFilterBetweenPlaylists], trackController.filterBar.isOpen {
            trackController.filterBar.close()
        }

        return .show
    }
}

extension ViewController: MediaKeyTapDelegate {
    func handle(mediaKey: MediaKey, event: KeyEvent) {
        switch mediaKey {
        case .playPause:
            _play.performClick(self)
        case .previous, .rewind:
            _previous.performClick(self)
        case .next, .fastForward:
            _next.performClick(self)
        }
    }
}

extension ViewController: NSPopoverDelegate {
    func popoverWillShow(_ notification: Notification) {
        _queueButton.state = .on
        _queueButton.layer!.backgroundColor = NSColor(white: 0.0, alpha: 0.25).cgColor
    }
    
    func popoverWillClose(_ notification: Notification) {
        _queueButton.state = .off
        _queueButton.layer!.backgroundColor = NSColor(white: 0.0, alpha: 0.1).cgColor
    }
}

extension ViewController: PlayerDelegate {
    func playerChangedTrack(_ player: Player) {
        self.updateTimesHidden(self)
        
        _previous.isEnabled = player.history.playingIndex >= 0
        _next.isEnabled = player.history.playingIndex < player.history.count && player.history.count > 0
        
        _queueButton.isEnabled = player.history.count > 0
        
        _waveformView.track = player.playing
        playingTrackController._emptyIndicator.isHidden = player.playing != nil

        guard let track = player.playing else {
            playingTrackController.history = PlayHistory(playlist: PlaylistEmpty())
            
            _waveformView.analysis = nil
            _waveformView.jumpSegment = 0
            
            return
        }
        
        if playingTrackController.history.track(at: 0) != track {
            playingTrackController.history.insert(tracks: [track], before: 0)
            playingTrackController._tableView.insertRows(at: IndexSet(integer: 0), withAnimation: .slideDown)
            
            if playingTrackController.history.count > 1 {
                // Two-step to get the animation rollin
                playingTrackController.history.remove(indices: [1])
                playingTrackController._tableView.removeRows(at: IndexSet(integer: 1), withAnimation: .effectFade)
            }
        }
        
        _waveformView.analysis = track.analysis
        
        if let speed = track.speed {
            // Always jump 16 beats
            _waveformView.jumpSegment = (speed.secondsPerBeat * 16) / player.player.duration
        }
        else {
            _waveformView.jumpSegment = 0
        }
    }
    
    func playerTriggeredRepeat(_ player: Player) {
        _repeat.spinOnce()
    }
    
    var currentHistory: PlayHistory? {
        return trackController.history
    }
}
