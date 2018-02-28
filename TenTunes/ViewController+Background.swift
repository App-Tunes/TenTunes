
//
//  ViewController+Background.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension ViewController {
    func startBackgroundTasks() {
        self.completionTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 300.0, repeats: true ) { [unowned self] (timer) in
            // Kids, don't try this at home
            // Really
            // Holy shit
            if self.isPlaying() && Int64(self.player.frameCount) - self.player.currentFrame < 100 {
                self.play(moved: 1)
            }
        }

        self.visualTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true ) { [unowned self] (timer) in
            self._spectrumView.setBy(player: self.player) // TODO Apparently this loops back when the track is done (or rather just before)
            
            if self.playing != nil, self._spectrumView.bounds.height > 30, !self.player.currentTime.isNaN {
                self._timePlayed.isHidden = false
                self._timeLeft.isHidden = false
                
                self._timePlayed.stringValue = Int(self.player.currentTime).timeString
                self._timeLeft.stringValue = Int(self.player.duration - self.player.currentTime).timeString
            }
            else {
                self._timePlayed.isHidden = true
                self._timeLeft.isHidden = true
            }
        }
        
        self.visualTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 10.0, repeats: true ) { [unowned self] (timer) in
            if self._workerSemaphore.wait(timeout: DispatchTime.now()) == .success {
                // Update the current playlist, top priority
                let desired = self.trackController.desired!
                
                let copy = PlayHistory(playlist: self.trackController.history.playlist)
                
                if desired._changed, desired.semaphore.wait(timeout: DispatchTime.now()) == .success {
                    desired._changed = false
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        desired.filter ?=> copy.filter
                        desired.sort ?=> copy.sort
                        
                        DispatchQueue.main.async {
                            self.trackController.history = copy
                            self._workerSemaphore.signal()
                            desired.semaphore.signal()
                        }
                    }
                }
                else if let playing = self.playing, playing.analysis == nil {
                    // Analyze the current file
                    
                    playing.analysis = Analysis()
                    self._spectrumView.analysis = playing.analysis
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        SPInterpreter.analyze(file: self.player.audioFile!, analysis: playing.analysis!)
                        self._workerSemaphore.signal()
                    }
                }
                else {
                    self.fetchOneMetadata()
                }
            }
        }
    }
    
    func fetchOneMetadata() {
        for view in trackController.visibleTracks {
            if let track = view.track, !track.metadataFetched  {
                fetchMetadata(for: track, updating: view)
                return
            }
        }
        
        for track in trackController.history.playlist.tracks {
            if !track.metadataFetched  {
                fetchMetadata(for: track, wait: true)
                return
            }
        }
        
        // Else we're done
        self._workerSemaphore.signal()
    }
    
    func fetchMetadata(for track: Track, updating: TrackCellView? = nil, wait: Bool = false) {
        DispatchQueue.global(qos: .userInitiated).async {
            track.fetchMetadata()
            
            // Update on main thread
            DispatchQueue.main.async {
                self.trackController.update(view: updating, with: track)
            }
            
            Thread.sleep(forTimeInterval: TimeInterval(wait ? 0.2 : 0.02))
            
            self._workerSemaphore.signal()
        }
        
    }
}
