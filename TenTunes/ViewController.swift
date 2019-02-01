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

func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

class ViewController: NSViewController {

    static var shared: ViewController!
    
    @IBOutlet var _coverImage: NSImageView!
    var coverImageObserver: NSKeyValueObservation?

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
    var trackController: TrackController!
    var playingTrackController: TrackController!
    var queueController: TrackController!
    
    var taskViewController: TaskViewController!
    
    override func viewDidLoad() {        
        trackController = TrackController(nibName: .init(rawValue: "TrackController"), bundle: nil)
        trackController.view.frame = _trackView.frame
        
        _trackGuardView.contentView = trackController.view
        _trackGuardView.delegate = self
        
        playingTrackController = TrackController(nibName: .init(rawValue: "TrackController"), bundle: nil)
        playingTrackController.view.frame = _playingTrackView.frame
        _playingTrackView.setFullSizeContent(playingTrackController.view)
        playingTrackController.titleify()
        
        playlistController = PlaylistController(nibName: .init(rawValue: "PlaylistController"), bundle: nil)
        playlistController.view.frame = _playlistView.frame
        _splitView.replaceSubview(_playlistView, with: playlistController.view)
        
        queueController = TrackController(nibName: .init(rawValue: "TrackController"), bundle: nil)
        
        taskViewController = TaskViewController(nibName: .init(rawValue: "TaskViewController"), bundle: nil)
        
        ViewController.shared = self
        
        player.delegate = self
        player.start()
        player.history = queueController.history // Empty but != nil
        
        playlistController.delegate = self
        playlistController.masterPlaylist = Library.shared.masterPlaylist
        playlistController.library = Library.shared.allTracks
        
        trackController.playTrack = { [unowned self] in
            self.player.play(at: $0, in: self.trackController.history) // TODO Support for multiple
            if let position = $1 {
                self.player.setPosition(position)
            }
        }
        trackController.playTrackNext = { [unowned self] in
            // TODO Support for multiple
            let next = [self.trackController.history.track(at: $0)!]
            self.player.enqueue(tracks: next, at: .start)
        }
        
        trackController.playTrackLater = { [unowned self] in
            // TODO Support for multiple
            let next = [self.trackController.history.track(at: $0)!]
            self.player.enqueue(tracks: next, at: .end)
        }
        
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
        queueController.playTrack = { [unowned self] in
            if self.player.history === self.queueController.history {
                self.player.play(moved: $0 - self.queueController.history.playingIndex)
                if let position = $1 {
                    self.player.setPosition(position)
                }
            }
        }
        
        taskPopover = NSPopover()
        taskPopover.contentViewController = taskViewController
        taskPopover.animates = true
        taskPopover.behavior = .transient
        
        _waveformView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateTimesHidden), name: NSView.frameDidChangeNotification, object: _waveformView)
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.keyDown(with: $0)
        }
        
        coverImageObserver = UserDefaults.standard.observe(\.titleBarStylization, options: [.initial, .new]) { (defaults, change) in
            self._coverImage.alphaValue = CGFloat(change.newValue ?? 0)
        }
        
        mediaKeyTap = MediaKeyTap(delegate: self, for: [.playPause, .previous, .rewind, .next, .fastForward])
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
}

extension ViewController: NSUserInterfaceValidations {
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        guard let action = item.action else {
            return false
        }
        
        if action == #selector(performFindEverywherePanelAction) { return true }

        return false
    }
    
    @IBAction func performFindEverywherePanelAction(_ sender: AnyObject) {
        playlistController.selectLibrary(self)
        trackController.performFindPanelAction(self)
    }
    
    @IBAction func findButtonClicked(_ sender: AnyObject) {
        guard playlistController.history.current != .library || !trackController.filterBar.isOpen else {
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
    func playlistController(_ controller: PlaylistController, selectionDidChange playlists: [PlaylistProtocol]) {
        guard !playlists.isEmpty else {
            return
        }
        
        if !UserDefaults.standard.keepFilterBetweenPlaylists, trackController.filterBar.isOpen {
            trackController.filterBar.close()
        }
        
        _trackGuardView.present(elements: playlists)
    }
    
    func playlistController(_ controller: PlaylistController, play playlist: PlaylistProtocol) {
        _trackGuardView.present(elements: [playlist])
        
        if (self.trackController.history.playlist as? Playlist) == (playlist as? Playlist) {
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
    func multiplicityGuard(_ view: MultiplicityGuardView, show elements: [Any]) -> MultiplicityGuardView.ShowAction {
        guard !elements.isEmpty else {
            return .error(text: view.errorSelectionEmpty)
        }
        
        let playlists = elements as! [PlaylistProtocol]
        if let playlist = playlists.onlyElement {
            self.trackController.desired.playlist = playlist
        }
        else if !playlists.isEmpty {
            self.trackController.desired.playlist = PlaylistMultiple(playlists: playlists)
        }
        
        return .show
    }
}

extension ViewController: MediaKeyTapDelegate {
    func handle(mediaKey: MediaKey, event: KeyEvent?) {
        switch mediaKey {
        case .playPause:
            _play.performClick(self)
        case .previous, .rewind:
            _previous.performClick(self)
        case .next, .fastForward:
            _next.performClick(self)
        default:
            break
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
        
        guard let track = player.playing else {
            playingTrackController.history = PlayHistory(playlist: PlaylistEmpty())
            
            _waveformView.analysis = nil
            _waveformView.jumpSegment = 0
            _waveformView.duration = 1
            
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
        
        _waveformView.duration = track.duration?.seconds ?? 1
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
