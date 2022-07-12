//
//  Player.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.04.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation
import TunesLogic
import AVFoundation

protocol PlayerDelegate : AnyObject {
    func playerTriggeredRepeat(_ player: Player)

    var currentHistory: PlayHistory? { get }
}

/// A player handling sequential plays of tracks with a history.
@objc class Player : NSObject, ObservableObject {
	static let normalizedLUFS: Float = -14
	static let minPlayTimePerListen = 0.5

    var history: PlayHistory = PlayHistory(playlist: PlaylistEmpty())
	var currentOutputDevice: AVAudioDevice? = .systemDefault {
		willSet { objectWillChange.send() }
		didSet { _restartDevice() }
	}
	
	@objc dynamic var playingEmitter: AVAudioEmitter?
	@objc dynamic var playing: Track?
	
	@objc dynamic var volume: Float = 1 {
		didSet { _updatePlayerVolume() }
	}
    
    weak var delegate: PlayerDelegate?
        
    var shuffle = true {
        didSet {
            (shuffle ? history.shuffle() : history.unshuffle())
        }
    }
    var `repeat` = true
    	
	var playCountCountdown: Countdown

    override init() {
		playCountCountdown = Countdown()

		super.init()

        playCountCountdown.action = { [unowned self] in
            self.playing?.playCount += 1
        }
    }
    
    @objc dynamic var isPlaying : Bool {
        playingEmitter?.node.isPlaying ?? false
    }
    
    var isPaused : Bool {
        !isPlaying
    }
    
    var currentTime: TimeInterval? {
		playingEmitter?.node.currentTime
    }
    
    var timeUntilNextTrack: Double? {
		guard let node = playingEmitter?.node else {
			return nil
		}
		
		return node.duration - node.currentTime
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
        
    func togglePlay() {
        if isPaused {
			self.resumePlay()
        }
        else {
            self.pause()
        }
    }
	
	func resumePlay() {
		guard let player = playingEmitter else {
			// TODO Start new track?
			return
		}

		guard isPaused else {
			return
		}
		
		playCountCountdown.resume()
		
		willChangeValue(for: \.isPlaying)
		player.node.play()
		didChangeValue(for: \.isPlaying)
	}

	func pause() {
		guard let player = playingEmitter, isPlaying else {
			return
		}

		playCountCountdown.pause()
		
		willChangeValue(for: \.isPlaying)
		player.node.stop()
		didChangeValue(for: \.isPlaying)
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
        
		if let player = playingEmitter, player.node.isPlaying {
			// It will likely stop playing anyway, but let's make sure.
			player.node.stop()
        }

        // We don't entirely know if it changes but it might, and we don't want to check on EVERY path here
        willChangeValue(for: \.isPlaying)
        defer {
            didChangeValue(for: \.isPlaying)
        }
        
        guard let track = track else {
			// Somebody decided we should stop playing
			// Or we're at start / end of list
			playing = nil
			return
		}
		
		guard let device = currentOutputDevice else {
			// Nowhere to play
			playing = nil
			return
		}
		
		guard let url = track.liveURL else {
			playing = nil
			
			throw PlayError.missing
		}
		
		do {
			let file = try AVAudioFile(forReading: url)

			guard file.duration < 100000 else {
				playing = nil
				throw PlayError.error(message: "File duration is too long! The file is probably bugged.") // Likely bugged file and we'd crash otherwise
			}
			
			playingEmitter = try preparePlayer(forFile: file, device: device)
		} catch let error {
			if error is PlayError { throw error }
			
			print(error.localizedDescription)
			playing = nil
			playingEmitter = nil
			
			throw PlayError.error(message: error.localizedDescription)
		}
						
		playingEmitter?.node.play()
		playing = track
		(playingEmitter?.node.duration).map {
			playCountCountdown.start(for: $0 * Player.minPlayTimePerListen)
		}
		_updatePlayerVolume()
		
		if !NSApp.isActive {
			notifyPlay(of: track)
		}
    }
	
	private func _restartDevice() {
		guard
			let player = playingEmitter,
			let device = currentOutputDevice
		else {
			// Nothing to play
			return
		}
		
		do {
			let wasPlaying = player.node.isPlaying
			if wasPlaying {
				player.node.stop()
			}
			
			let newPlayer = try preparePlayer(forFile: player.node.file, device: device)
			try newPlayer.node.move(to: player.node.currentTime)

			if wasPlaying {
				newPlayer.node.play()
			}

			self.playingEmitter = newPlayer
		} catch let error {
			NSAlert.warning(title: "Error when switching devices", text: error.localizedDescription)
		}
	}
	
	private func preparePlayer(forFile file: AVAudioFile, device: AVAudioDevice) throws -> AVAudioEmitter {
		let newPlayer = try device.prepare(file)
		
		newPlayer.node.didFinishPlaying = { [weak self, weak newPlayer] in
			guard self?.playingEmitter == newPlayer else {
				return
			}
			
			// We're in an audio thread; move to main.
			DispatchQueue.main.async {
				self?.play(moved: 1)
			}
		}
		
		return newPlayer
	}
	
	private func _updatePlayerVolume() {
		guard let playing = playing, let player = playingEmitter else {
			return
		}
		
		var playerVolume = volume
		if AppDelegate.defaults[.useNormalizedVolumes] {
			let requiredLoudnessAdjustmentDB = Self.normalizedLUFS - playing.loudness
			let requiredLoudnessAdjustmentVolume = exp2(requiredLoudnessAdjustmentDB / 10)
			playerVolume *= min(1.0, requiredLoudnessAdjustmentVolume)
		}
		player.node.volume = playerVolume
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
    
    func setPosition(_ position: TimeInterval) {
		try? playingEmitter?.node.move(to: position)
    }
    
	func movePosition(_ movement: TimeInterval) {
		try? playingEmitter?.node.move(by: movement)
	}
	        
    override class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        return key != #keyPath(isPlaying)
    }
    
//    override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
//        return [
            // TODO This doesn't work yet unfortunately, but is observed manually
//            #keyPath(Player.isPlaying): [#keyPath(Player.player.isPlaying)],
//            ][key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
//    }
}
