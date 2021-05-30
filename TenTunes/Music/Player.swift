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
    // TODO Same as setPosition, but for some reason this func doesn't exist currently??
    func jump(to position: Double) {
        startTime = position
        if isPlaying {
            stop()
            play()
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

protocol PlayerDelegate : class {
    func playerTriggeredRepeat(_ player: Player)

    var currentHistory: PlayHistory? { get }
}

class Countdown {
    var action: (() -> Void)?
    
    private var timer: Timer?
    private var timeLeft: Double?
    
    init(action: (() -> Void)? = nil) {
        self.action = action
    }
    
    private func start() {
        
    }
    
    func start(for seconds: TimeInterval) {
        timeLeft = nil
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [unowned self] _ in
            self.action?()
        }
    }
    
    func pause() {
        timeLeft = (timer?.fireDate).map { $0.timeIntervalSinceNow } ?? nil
        if (timeLeft ?? 0) <= 0 { timeLeft = nil }
        
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        timeLeft.map(start)
    }
    
    func stop() {
        timeLeft = nil
        timer?.invalidate()
        timer = nil
    }
}

@objc class Player : NSObject {
    static let minPlayTimePerListen = 0.5
    
    var history: PlayHistory = PlayHistory(playlist: PlaylistEmpty())
    @objc dynamic var player: AKPlayer
    @objc dynamic var backingPlayer: AKPlayer
    @objc dynamic var playing: Track?
    
    weak var delegate: PlayerDelegate?
    
    var mixer: AKMixer
    @objc var outputNode: AKBooster
    
    var shuffle = true {
        didSet {
            (shuffle ? history.shuffle() : history.unshuffle())
        }
    }
    var `repeat` = true
    
    var startTime = 0.0
    
    var playCountCountdown: Countdown

    override init() {
        player = AKPlayer()
        backingPlayer = AKPlayer()
        mixer = AKMixer(player, backingPlayer)
        outputNode = AKBooster(mixer)
        outputNode.gain = 0.7
        
        playCountCountdown = Countdown()

        super.init()

        playCountCountdown.action = { [unowned self] in
            self.playing?.playCount += 1
        }
        player.completionHandler = completionHandler(for: player)
        backingPlayer.completionHandler = completionHandler(for: backingPlayer)
    }
    
    func start() {
        AKManager.output = outputNode
    }
    
    @objc dynamic var isPlaying : Bool {
        return player.isPlaying
    }
    
    var isPaused : Bool {
        return !isPlaying
    }
    
    var currentTime: Double? {
        guard isPlaying else {
            return startTime
        }
        
        // Apparently this is really hard to get? lol
        guard player.audioFile != nil, let stamp = player.avAudioNode.lastRenderTime?.audioTimeStamp, stamp.mFlags.contains(.hostTimeValid) && stamp.mFlags.contains(.sampleTimeValid) else {
            return nil
        }
        
        return player.currentTime
    }
    
    var timeUntilNextTrack: Double? {
        return currentTime.map {
            player.duration - $0
        }
    }

    func play(at: Int?, in history: PlayHistory?) {
        if let history = history {
            self.history = PlayHistory(from: history)
        }
        
        self.history.move(to: at ?? -1)
        if shuffle && history != nil { self.history.shuffle() } // Move there before shuffling so the position is retained
        if at == nil { self.history.move(to: 0) }
        
        let track = self.history.playingTrack
        
        do {
            try play(track: track)
        }
        catch PlayError.missing {
            if TrackActions.askReplacement(for: track!) {
                play(at: at, in: history)
            }
        }
        catch PlayError.error(let message) {
            NSAlert.warning(title: "Error", text: message ?? "An unknown error occured when playing the file.")
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
            notification.perform(Selector(("set_identityImage:")), with: of.artworkPreview ?? Album.missingArtwork)
        }
        else {
            print("Failed to set identity image of notification!")
        }
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func sanityCheck() {
        if !AKManager.engine.isRunning {
            if (try? AKManager.start()) == nil {
                print("Failed to start audio engine!")
            }
        }
    }
    
    func restartPlay() {
        guard isPlaying else {
            return
        }
        
        willChangeValue(for: \.isPlaying)
        
        sanityCheck()
        let currentTime = player.currentTime
        player.pause()
        player.play(from: currentTime, to: player.duration)
        
        didChangeValue(for: \.isPlaying)
    }
    
    func togglePlay() {
        if isPaused {
            sanityCheck()
            playCountCountdown.resume()
            
            willChangeValue(for: \.isPlaying)
            player.play(from: startTime, to: player.duration)
            didChangeValue(for: \.isPlaying)
        }
        else {
            self.pause()
        }
    }

    enum PlayError : Error {
        case missing
        case error(message: String?)
    }
    
    func enqueue(tracks: [Track], at: PlayHistory.QueueLocation) {
        history.enqueue(tracks: tracks, at: at)
    }

    func play(track: Track?) throws {
        playCountCountdown.stop()
        
        if player.isPlaying {
            player.stop()
        }

        // We don't entirely know if it changes but it might, and we don't want to check on EVERY path here
        willChangeValue(for: \.isPlaying)
        defer {
            didChangeValue(for: \.isPlaying)
        }

        sanityCheck()
        
        if let track = track {
            if let url = track.liveURL {
                do {
                    let akfile = try AKAudioFile(forReading: url)

                    guard akfile.duration < 100000 else {
                        playing = nil
                        throw PlayError.error(message: "File duration is too long! The file is probably bugged.") // Likely bugged file and we'd crash otherwise
                    }
                    
                    player.stop()
                    
                    try player.load(audioFile: akfile)
                    try backingPlayer.load(audioFile: akfile)
                } catch let error {
                    if error is PlayError { throw error }
                    
                    print(error.localizedDescription)
                    player.stop()
                    playing = nil
                    
                    throw PlayError.error(message: error.localizedDescription)
                }
                
                // Apparently players are currently sometimes unusable after load
                // for a second or so
                swapPlayers()
                
                player.play(from: 0)
                playing = track
                playing?.duration.map {
                    playCountCountdown.start(for: $0.seconds * Player.minPlayTimePerListen)
                }
                
                mixer.volume = AppDelegate.defaults[.useNormalizedVolumes]
                    ? max(0.5, min(1.5, 1.0 / track.loudness)) : 1.0
                
                if !NSApp.isActive {
                    notifyPlay(of: track)
                }
            }
            else {
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
        if moved == 0 {
            guard history.count > 0 && history.playingIndex < history.count else {
                play(at: nil, in: delegate?.currentHistory ?? PlayHistory(playlist: PlaylistEmpty()))
                return
            }

            history.shuffle()
            history.move(to: 0) // Select random track next
        }
        
        if self.repeat && history.playingIndex + moved == history.count {
            play(at: nil, in: history)
            delegate?.playerTriggeredRepeat(self)
            return
        }
        
        let didPlay = (try? play(track: history.move(by: moved))) != nil
        
        // Should play but didn't
        // And we are trying to move in some direction
        if moved != 0, history.playingTrack != nil, !didPlay {
            if let playing = playing {
                print("Skipped unplayable track \(playing.objectID.description): \(String(describing: playing.path))")
            }
            
            play(moved: moved)
        }
    }
    
    func swapPlayers() {
        let _player = self.player
        self.player = self.backingPlayer
        self.backingPlayer = _player
    }
    
    func setPosition(_ position: Double, smooth: Bool = true) {
        guard abs(position - player.currentTime) > 0.04 else {
            return // Baaasically the same, so skip doing extra work
        }
        
        guard isPlaying else {
            startTime = position
            return
        }
        
        sanityCheck()
        
        guard smooth else {
            player.jump(to: position)
            return
        }
        
        // This code block makes jumping the tiniest bit smoother
        // TODO Maybe determine this heuristically? lol
        let magicAdd = 0.04 // Hacky absolute that makes it even smoother
        backingPlayer.jump(to: position + magicAdd)
        backingPlayer.volume = 0
        backingPlayer.play()
        
        swapPlayers()

        // Slowly switch states. Kinda hacky but improves listening result
        for _ in 0 ..< 100 {
            player.volume += 1.0 / 100
            backingPlayer.volume -= 1.0 / 100
            Thread.sleep(forTimeInterval: 0.001)
        }
        
        backingPlayer.stop()
        player.volume = 1
        backingPlayer.volume = 1
    }
    
	func movePosition(_ movement: Double, smooth: Bool = true) {
		self.setPosition(player.currentTime + movement, smooth: smooth)
	}
	
    func pause() {
        playCountCountdown.pause()
        
        sanityCheck()

        willChangeValue(for: \.isPlaying)

        // The set position is reset when we play again
        startTime = player.currentTime
        player.stop()
        
        didChangeValue(for: \.isPlaying)
    }
        
    override class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        return key != #keyPath(isPlaying)
    }
    
    func completionHandler(for player: AKPlayer) -> () -> Void {
        return { [unowned self] in
            // If < 0.01, it's probably bugged. No track is that short
            if self.player == player {
                self.play(moved: 1)
            }
        }
    }

//    override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
//        return [
            // TODO This doesn't work yet unfortunately, but is observed manually
//            #keyPath(Player.isPlaying): [#keyPath(Player.player.isPlaying)],
//            ][key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
//    }
}
