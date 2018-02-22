//
//  ViewController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import Foundation
import AudioKit
import AudioKitUI

let playString = "▶"
let pauseString = "||"

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

func setButtonText(button: NSButton, text: String) {
    button.attributedTitle = NSAttributedString(string: text, attributes: button.attributedTitle.fontAttributes(in: NSRange(location: 0, length: button.attributedTitle.length)))
}

func setButtonColor(button: NSButton, color: NSColor) {
    if let mutableAttributedTitle = button.attributedTitle.mutableCopy() as? NSMutableAttributedString {
        mutableAttributedTitle.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutableAttributedTitle.length))
        button.attributedTitle = mutableAttributedTitle
    }
}

class ViewController: NSViewController {

    @IBOutlet var _tableView: NSTableView!
    @IBOutlet var _title: NSTextField!
    @IBOutlet var _subtitle: NSTextField!
    
    @IBOutlet var _play: NSButton!
    @IBOutlet var _stop: NSButton!
    @IBOutlet var _previous: NSButton!
    @IBOutlet var _next: NSButton!
    
    @IBOutlet var _spectrumView: TrackSpectrumView!
    
    var database: [Track]! = []
    
    var player: AKPlayer!
    var playing: Track?
    var playingIndex: Int?
    
    var visualTimer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.layer!.backgroundColor = NSColor.darkGray.cgColor
        
        setButtonColor(button: _play, color: NSColor.white)
        setButtonColor(button: _previous, color: NSColor.white)
        setButtonColor(button: _next, color: NSColor.white)

        self.player = AKPlayer()
        AudioKit.output = self.player
        try! AudioKit.start()

        let path = "/Volumes/Lukebox/iTunes/iTunes Library.xml"
        
        if !FileManager.default.fileExists(atPath: path) {
            print("FILE UNAVAILABLE")
            exit(1)
        }

        let nsdict = NSDictionary(contentsOfFile: path)!
        let tracksRaw = nsdict.object(forKey: "Tracks") as! NSDictionary
        
        for (_, trackData) in tracksRaw {
            let trackData = trackData as! NSDictionary
            
            let track = Track()
            
            track.title = trackData["Name"] as? String
            track.author = trackData["Artist"] as? String
            track.album = trackData["Album"] as? String
            track.path = trackData["Location"] as? String

            track.length = trackData["Total Time"] as? Int
            
            self.database.append(track)
        }
        
        self.updatePlaying()
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            return self.keyDown(with: $0)
        }
        
        self.visualTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true ) { [unowned self] (timer) in
            self._spectrumView.setBy(player: self.player)
            
            // Only fetch one at once
            if !self._fetchingMetadata {
                self.fetchOneMetadata()
            }
        }
    }
    
    var _fetchingMetadata: Bool = false
    
    func fetchOneMetadata() {
        if let visibleRect = self._tableView.enclosingScrollView?.contentView.visibleRect {
            let visibleRows = self._tableView.rows(in: visibleRect)
            
            for row in visibleRows.lowerBound...visibleRows.upperBound {
                if let view = self._tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? TrackCellView {
                    if let track = view.track, !track.metadataFetched {
                        
                        self._fetchingMetadata = true
                        DispatchQueue.global(qos: .userInitiated).async {
                            track.fetchMetadata()
                            
                            // Update on main thread
                            DispatchQueue.main.async {
                                view.imageView?.image = track.rArtwork
                                view.keyTextField?.attributedStringValue = track.rKey
                                view.bpmTextField?.stringValue = track.bpm?.description ?? ""
                            }
                            
                            self._fetchingMetadata = false
                        }
                        
                        return
                    }
                }
            }
        }
    }
    
    override var representedObject: Any? {
        didSet {
            
        }
    }
    
    func isPlaying() -> Bool {
        return self.player.isPlaying
    }

    func isPaused() -> Bool {
        return !self.isPlaying()
    }

    func updatePlaying() {
        guard let track = self.playing else {
            self.player.stop()

            setButtonText(button: self._play, text: playString)
            
            self._title.stringValue = ""
            self._subtitle.stringValue = ""
            
            return
        }
        
        setButtonText(button: self._play, text: self.isPaused() ? playString : pauseString)
        
        self._title.stringValue = track.rTitle()
        self._subtitle.stringValue = "\(track.rAuthor()) - \(track.rAlbum())"
    }
    
    func play(track: Track?) -> Void {
        if player.isPlaying {
            player.stop()
        }
        
        if let track = track, let url = track.url {
            do {
                let akfile = try AKAudioFile(forReading: url)
                
                // Async anyway so run first
                self._spectrumView.analyze(file: akfile)
                
                self.player.load(audioFile: akfile)
                
                player.play()
                self.playing = track
            } catch let error {
                print(error.localizedDescription)
                self.player.stop()
                self.playing = nil
                self._spectrumView.analyze(file: nil)
            }
        }
        else {
            self.player.stop()
            self.playing = nil
            self._spectrumView.analyze(file: nil)
        }
        
        self.updatePlaying()
    }
    
    @IBAction func doubleClick(_ sender: Any) {
        self.playingIndex = self._tableView.clickedRow
        self.play(track: self.database[self.playingIndex!])
    }
    
    func playCurrentTrack() {
        let selectedRow = self._tableView.selectedRow
        if selectedRow >= 0 {
            self.playingIndex = selectedRow
            self.play(track: self.database[selectedRow])
        }
    }
    
    @IBAction func play(_ sender: Any) {
        if self.playing != nil {
            if self.isPaused() {
                self.player.play()
            }
            else {
                self.player.play(from: self.player.currentTime, to: self.player.duration)
                self.player.stop()
            }
        }
        else {
            self.playCurrentTrack()
        }
        
        self.updatePlaying()
    }
    
    @IBAction func stop(_ sender: Any) {
        self.play(track: nil)
    }
    
    func play(moved: Int) {
        guard let database = self.database else {
            self.playingIndex = nil
            return
        }
        
        if let playingIndex = self.playingIndex {
            self.playingIndex = playingIndex + moved
        }
        else {
            self.playingIndex = moved > 0 ? 0 : database.count - 1
        }
        
        if self.playingIndex! >= database.count || self.playingIndex! < 0 {
            self.playingIndex = nil
            self.play(track: nil)
            return
        }
        
        let track = self.database?[self.playingIndex!]
        self.play(track: track)
        
        if track == nil {
            self.playingIndex = nil
        }
    }
    
    @IBAction func nextTrack(_ sender: Any) {
        self.play(moved: 1)
    }
    
    @IBAction func previousTrack(_ sender: Any) {
        self.play(moved: -1)
    }
    
    func keyDown(with event: NSEvent) -> NSEvent? {
        if let keyString = event.charactersIgnoringModifiers, keyString == " " {
            self._play.performClick(self)
        }
        else if Keycodes.enterKey.matches(event: event) || Keycodes.returnKey.matches(event: event) {
            self.playCurrentTrack()
        }
        else {
            return event
        }

        return nil
    }
    
    @IBAction func clickSpectrumView(_ sender: Any) {
        if self.player.isPlaying {
            self.player.stop()
            self.player.play(from: self._spectrumView.getBy(player: self.player)!, to: self.player.duration)
        }
        else {
            self.player.play(from: self._spectrumView.getBy(player: self.player)!, to: self.player.duration)
            self.player.stop()
        }
    }
}

extension ViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let NameCell = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
        static let DateCell = NSUserInterfaceItemIdentifier(rawValue: "dateCell")
        static let SizeCell = NSUserInterfaceItemIdentifier(rawValue: "sizeCell")
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        
        // 1
        let track = self.database[row]
        
        // 2
        if tableColumn == tableView.tableColumns[0] {
            if let view = tableView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? TrackCellView {
                let artist = track.rAuthor()
                let title = track.rTitle()
                let album = track.rAlbum()

                view.track = track
                view.textField?.stringValue = title
                view.subtitleTextField?.stringValue = "\(artist) - (\(album))"
                view.lengthTextField?.stringValue = track.rLength()
                view.imageView?.image = track.rArtwork
                view.key = track.rKey
                view.bpmTextField?.stringValue = ""

                return view
            }
        } else if tableColumn == tableView.tableColumns[1] {
            
        } else if tableColumn == tableView.tableColumns[2] {
            
        }
        
        return nil
    }
}

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return database.count;
    }
}

