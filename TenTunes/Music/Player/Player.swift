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
	@objc dynamic var playingTrack: Track?
	
	@objc dynamic var volume: Float = 1 {
		didSet { _updateEmitterVolume() }
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
            self.playingTrack?.playCount += 1
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
		guard let playingEmitter = playingEmitter else {
			// TODO Start new track?
			return
		}

		guard isPaused else {
			return
		}
		
		playCountCountdown.resume()
		
		willChangeValue(for: \.isPlaying)
		playingEmitter.node.play()
		didChangeValue(for: \.isPlaying)
	}

	func pause() {
		guard let playingEmitter = playingEmitter, isPlaying else {
			return
		}

		playCountCountdown.pause()
		
		willChangeValue(for: \.isPlaying)
		playingEmitter.node.stop()
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
        
		if let oldEmitter = playingEmitter, oldEmitter.node.isPlaying {
			// It will likely stop playing anyway, but let's make sure.
			oldEmitter.node.stop()
        }

        // We don't entirely know if it changes but it might, and we don't want to check on EVERY path here
        willChangeValue(for: \.isPlaying)
        defer {
            didChangeValue(for: \.isPlaying)
        }
        
        guard let track = track else {
			// Somebody decided we should stop playing
			// Or we're at start / end of list
			playingTrack = nil
			return
		}
		
		guard let device = currentOutputDevice else {
			// Nowhere to play
			playingTrack = nil
			return
		}
		
		guard let url = track.liveURL else {
			playingTrack = nil
			
			throw PlayError.missing
		}
		
		do {
			let file = try AVAudioFile(forReading: url)

			guard file.duration < 100000 else {
				playingTrack = nil
				throw PlayError.error(message: "File duration is too long! The file is probably bugged.") // Likely bugged file and we'd crash otherwise
			}
			
			playingEmitter = try prepareEmitter(forFile: file, device: device)
		} catch let error {
			if error is PlayError { throw error }
			
			print(error.localizedDescription)
			playingTrack = nil
			playingEmitter = nil
			
			throw PlayError.error(message: error.localizedDescription)
		}
						
		playingEmitter?.node.play()
		playingTrack = track
		(playingEmitter?.node.duration).map {
			playCountCountdown.start(for: $0 * Player.minPlayTimePerListen)
		}
		_updateEmitterVolume()
		
		if !NSApp.isActive {
			notifyPlay(of: track)
		}
    }
	
	private func _restartDevice() {
		guard
			let playingEmitter = playingEmitter,
			let device = currentOutputDevice
		else {
			// Nothing to play
			return
		}
		
		do {
			let wasPlaying = playingEmitter.node.isPlaying
			if wasPlaying {
				playingEmitter.node.stop()
			}
			
			let newEmitter = try prepareEmitter(forFile: playingEmitter.node.file, device: device)
			try newEmitter.node.move(to: playingEmitter.node.currentTime)

			if wasPlaying {
				newEmitter.node.play()
			}

			self.playingEmitter = newEmitter
		} catch let error {
			NSAlert.warning(title: "Error when switching devices", text: error.localizedDescription)
		}
	}
	
	private func prepareEmitter(forFile file: AVAudioFile, device: AVAudioDevice) throws -> AVAudioEmitter {
		let newEmitter = try device.prepare(file)
		
		newEmitter.node.didFinishPlaying = { [weak self, weak newEmitter] in
			guard self?.playingEmitter == newEmitter else {
				return
			}
			
			// We're in an audio thread; move to main.
			DispatchQueue.main.async {
				self?.play(moved: 1)
			}
		}
		
		return newEmitter
	}
	
	private func _updateEmitterVolume() {
		guard let playingTrack = playingTrack, let playingEmitter = playingEmitter else {
			return
		}
		
		var emitterVolume = volume
		if AppDelegate.defaults[.useNormalizedVolumes] {
			let requiredLoudnessAdjustmentDB = Self.normalizedLUFS - playingTrack.loudness
			let requiredLoudnessAdjustmentVolume = exp2(requiredLoudnessAdjustmentDB / 10)
			emitterVolume *= min(1.0, requiredLoudnessAdjustmentVolume)
		}
		playingEmitter.node.volume = emitterVolume
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
            if let playingTrack = playingTrack {
                print("Skipped unplayable track \(playingTrack.objectID.description): \(String(describing: playingTrack.path))")
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
