//
//  Player.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.04.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation
import AudioKit

extension AKPlayer {
    func createFakeCompletionHandler(completion: @escaping () -> Swift.Void) -> Timer {
        return Timer.scheduledTimer(withTimeInterval: 1.0 / 300.0, repeats: true ) { [unowned self] (timer) in
            // Kids, don't try this at home
            // Really
            // Holy shit
            if self.isPlaying && Int64(self.frameCount) - self.currentFrame < 100 {
                completion()
            }
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

class Player {
    var history: PlayHistory?
    var player: AKPlayer!
    var playing: Track?
    
    var completionTimer: Timer?
    
    var updatePlaying: ((Track?) -> Swift.Void)?
    var historyProvider: (() -> PlayHistory)?

    var shuffle = true {
        didSet {
            (shuffle ? history?.shuffle() : history?.unshuffle())
        }
    }

    init() {
        player = AKPlayer()
        // The completion handler sucks...
        // TODO When it stops sucking, replace our completion timer hack
        //        self.player.completionHandler =
        completionTimer = player.createFakeCompletionHandler { [unowned self] in
            self.play(moved: 1)
        }
    }
    
    func start() {
        AudioKit.output = self.player
        try! AudioKit.start()
    }
    
    
    func isPlaying() -> Bool {
        return self.player.isPlaying
    }
    
    func isPaused() -> Bool {
        return !self.isPlaying()
    }

    func play(at: Int?, in history: PlayHistory) {
        self.history = PlayHistory(from: history)
        
        self.history!.move(to: at ?? -1)
        if shuffle { self.history!.shuffle() } // Move there before shuffling so the position is retained
        if at == nil { self.history!.move(to: 0) }
        
        let track = self.history!.playingTrack
        
        do {
            try play(track: track)
        }
        catch PlayError.missing {
            let track = track!
            let alert: NSAlert = NSAlert()
            if track.path == nil {
                alert.messageText = "Invalid File"
                alert.informativeText = "The file could not be played since no path is provided"
            }
            else {
                alert.messageText = "Missing File"
                alert.informativeText = "The file could not be played since the file could not be found"
            }
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        catch PlayError.error(let message) {
            let alert: NSAlert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = message ?? "An unknown error occured when playing the file"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        catch let error {
            fatalError(error.localizedDescription)
        }
    }
    
    func notifyPlay(of: Track) {
        let notification = NSUserNotification()
        notification.title = of.rTitle
        notification.subtitle = of.rSource
        if notification.responds(to: Selector(("set_identityImage:"))) {
            notification.perform(Selector(("set_identityImage:")), with: of.rPreview)
        }
        else {
            print("Failed to set identity image of notification!")
        }
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func togglePlay() {        
        if self.isPaused() {
            self.player.play()
        }
        else {
            self.pause()
        }
    }

    enum PlayError : Error {
        case missing
        case error(message: String?)
    }
    
    func enqueue(tracks: [Track]) {
        if history == nil {
            let history = PlayHistory(playlist: PlaylistEmpty())
            play(at: -1, in: history)
        }
        
        history!.insert(tracks: tracks, before: history!.playingIndex + 1)
    }

    func play(track: Track?) throws {
        defer {
            if let updatePlaying = updatePlaying {
                updatePlaying(playing)
            }
        }
        
        if player.isPlaying {
            player.stop()
        }
        
        if !AudioKit.engine.isRunning {
            try! AudioKit.start()
        }
        
        if let track = track {
            if let url = track.url {
                do {
                    let akfile = try AKAudioFile(forReading: url)
                    player.load(audioFile: akfile)
                } catch let error {
                    print(error.localizedDescription)
                    player.stop()
                    playing = nil
                    
                    throw PlayError.error(message: error.localizedDescription)
                }
                
                guard player.duration < 100000 else {
                    playing = nil
                    throw PlayError.error(message: "File duration is too long! The file is probably bugged.") // Likely bugged file and we'd crash otherwise
                }
                
                player.play()
                playing = track
                
                if !NSApp.isActive {
                    notifyPlay(of: track)
                }
            }
            else {
                // We are at a track but it's not playable :<
                playing = nil
                
                throw PlayError.missing
            }
        }
        else {
            // Somebody decided we should stop playing
            // Or we're at start / end of list
            playing = nil
        }
    }
    
    func play(moved: Int) {
        if history == nil {
            guard let historyProvider = historyProvider else {
                return
            }
            play(at: nil, in: historyProvider())
        }
        else if moved == 0 {
            history!.shuffle()
            history!.move(to: 0) // Select random track next
        }
        
        let didPlay = (try? play(track: history!.move(by: moved))) != nil
        
        // Should play but didn't
        // And we are trying to move in some direction
        if moved != 0, history?.playingTrack != nil, !didPlay {
            if let playing = playing {
                print("Skipped unplayable track \(playing.objectID.description): \(String(describing: playing.path))")
            }
            
            play(moved: moved)
        }
    }
    
    func setPosition(_ position: Double) {
        player.setPosition(position * player.duration)
    }
    
    func pause() {
        // The set position is reset when we play again
        player.play(from: player.currentTime, to: player.duration)
        player.stop()
        
        if let updatePlaying = updatePlaying {
            updatePlaying(playing)
        }
    }
}
