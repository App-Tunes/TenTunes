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

let playString = "▶"
let pauseString = "||"

func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

class ViewController: NSViewController {

    static var shared: ViewController!
    
    @IBOutlet var _title: NSTextField!
    @IBOutlet var _subtitle: NSTextField!
    @IBOutlet var _coverImage: NSImageViewAspectFill!
    
    @IBOutlet var _play: NSButton!
    @IBOutlet var _stop: NSButton!
    @IBOutlet var _previous: NSButton!
    @IBOutlet var _next: NSButton!
    
    @IBOutlet var _waveformView: WaveformView!
    
    @IBOutlet var _shuffle: NSButton!
    
    @IBOutlet var _timePlayed: NSTextField!
    @IBOutlet var _timeLeft: NSTextField!
    
    @IBOutlet var _volume: NSSlider!

    @IBOutlet var _playlistView: NSView!
    @IBOutlet var _trackView: NSView!
    @IBOutlet var _splitView: NSSplitView!
    
    var queuePopover: NSPopover!
        
    var visualTimer: Timer!
    var backgroundTimer: Timer!
    
    let player: Player = Player()

    var _workerSemaphore = DispatchSemaphore(value: 3)
    var metadataToDo: [Track] = []
    var analysisToDo: Set<Track> = Set()
    
    var mediaKeyTap: MediaKeyTap?
    
    var playlistController: PlaylistController!
    var trackController: TrackController!
    var queueController: TrackController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ValueTransformers.register()

        trackController = TrackController(nibName: NSNib.Name(rawValue: "TrackController"), bundle: nil)
        trackController.view.frame = _trackView.frame
        _splitView.replaceSubview(_trackView, with: trackController.view)
        
        playlistController = PlaylistController(nibName: NSNib.Name(rawValue: "PlaylistController"), bundle: nil)
        playlistController.view.frame = _playlistView.frame
        _splitView.replaceSubview(_playlistView, with: playlistController.view)

        queueController = TrackController(nibName: NSNib.Name(rawValue: "TrackController"), bundle: nil)

        ViewController.shared = self
        
        player.updatePlaying = { [unowned self] playing in
            self.updatePlaying()
        }
        player.historyProvider = { [unowned self] in
            return self.trackController.history
        }
        player.start()
                
        self.playlistController.selectionDidChange = { [unowned self] in
            self.playlistSelected($0)
        }
        self.playlistController.playPlaylist = { [unowned self] in
            self.playlistSelected($0)
            self.player.play(at: nil, in: self.trackController.history)
        }
        self.playlistController.masterPlaylist = Library.shared.masterPlaylist
        self.playlistController.library = Library.shared.allTracks

        trackController.playTrack = { [unowned self] in
            self.player.play(at: $0, in: self.trackController.history) // TODO Support for multiple
            if let position = $1 {
                self.player.setPosition(position)
            }
        }
        trackController.playTrackNext = { [unowned self] in
            // TODO Support for multiple
            // TODO What if history doesn't exist? No feedback!!
            let next = [self.trackController.history.track(at: $0)!]
            self.player.history?.insert(tracks: next, before: self.player.history!.playingIndex + 1)
        }
        trackController.desired.playlist = Library.shared.allTracks

        queuePopover = NSPopover()
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

        self.updatePlaying()
        
        _waveformView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateTimesHidden), name: NSView.frameDidChangeNotification, object: _waveformView)
        
        _coverImage.layer!.opacity = 0.08
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.keyDown(with: $0)
        }
        
        registerObservers()
        
        mediaKeyTap = MediaKeyTap(delegate: self)
        mediaKeyTap?.start()

        startBackgroundTasks()
    }
    
    override func viewDidAppear() {
        self.view.window!.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        
        _timePlayed.alphaValue = 0.5
        _timeLeft.alphaValue = 0.5
        
        if self.view.window!.appearance?.name == NSAppearance.Name.vibrantDark {
            _play.set(color: NSColor.lightGray)
            _previous.set(color: NSColor.lightGray)
            _next.set(color: NSColor.lightGray)
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
    
    func updatePlaying() {
        self.updateTimesHidden(self)
        
        guard let track = player.playing else {
            _play.set(text: playString)
            
            self._title.stringValue = ""
            self._subtitle.stringValue = ""
            _coverImage.image = nil
            _waveformView.analysis = nil

            return
        }
        
        _play.set(text: player.isPaused() ? playString : pauseString)
        
        _title.stringValue = track.rTitle
        _subtitle.stringValue = track.rSource
        _coverImage.image = track.artworkPreview
        _waveformView.analysis = track.analysis
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
        if let position = self._waveformView.getBy(max: 1) {
            self.player.setPosition(position)
        }
    }
    
    @IBAction func toggleShuffle(_ sender: Any) {
        player.shuffle = !player.shuffle
        let img = NSImage(named: NSImage.Name(rawValue: "shuffle"))
        _shuffle.image = player.shuffle ? img : img?.tinted(in: NSColor.gray)
    }
        
    func playlistSelected(_ playlist: PlaylistProtocol) {
        trackController.desired.playlist = playlist
    }
    
    @IBAction func volumeChanged(_ sender: Any) {
        player.player.volume = Double(pow(Float(_volume.intValue) / 100, 2))
    }
    
    @IBAction func showQueue(_ sender: Any) {
        let view = sender as! NSView
        
        guard let history = player.history else {
            return // TODO Disable button
        }
        
        if !queueController.isViewLoaded {
            queueController.loadView()
            queueController.queueify()
        }
        
        queueController.history = history
        queueController._tableView?.reloadData() // If it didn't change it doesn't reload automatically
        queuePopover.appearance = view.window!.appearance
        
        // TODO Show a divider on top
        queueController._tableView.scrollRowToTop(history.playingIndex)
        queuePopover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
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
