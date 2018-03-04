
//
//  ViewController+Background.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension ViewController {    
    func endTask() {
        self._workerSemaphore.signal()
    }
    
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
            guard self.view.window?.isVisible ?? false else {
                return
            }
            
            self._spectrumView.setBy(player: self.player)
            
            if !self._timePlayed.isHidden, !self._timeLeft.isHidden {
                self._timePlayed.stringValue = Int(self.player.currentTime).timeString
                self._timeLeft.stringValue = Int(self.player.duration - self.player.currentTime).timeString
            }
        }
        
        self.backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 10.0, repeats: true ) { [unowned self] (timer) in
            if self._workerSemaphore.wait(timeout: DispatchTime.now()) == .success {
                
                // Update the current playlist, top priority
                if let desired = self.trackController.desired, desired._changed, desired.semaphore.wait(timeout: DispatchTime.now()) == .success {
                    let copy = PlayHistory(playlist: self.trackController.history.playlist)
                    desired._changed = false
                    
                    Library.shared.performInBackground { mox in
                        copy.convert(to: mox)
                        desired.filter ?=> copy.filter
                        desired.sort ?=> copy.sort
                        
                        DispatchQueue.main.async {
                            copy.convert(to: Library.shared.viewMox)
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
                    self.trackController.update(view: nil, with: playing) // Get the analysis inside the cell
                    
                    Library.shared.performInBackground { mox in
                        let asyncTrack = mox.convert(playing)
                        asyncTrack.analysis = playing.analysis
                        
                        // May exist on disk
                        if !asyncTrack.readAnalysis() {
                            SPInterpreter.analyze(file: self.player.audioFile!, analysis: asyncTrack.analysis!)
                            asyncTrack.writeAnalysis()
                        }
                        try! mox.save()
                        
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
        if view.window?.isVisible ?? false {
            for view in trackController.visibleTracks {
                if let track = view.track, !track.metadataFetched  {
                    fetchMetadata(for: track, updating: view)
                    return
                }
            }
            
            // TODO Replace this with a library-caused search
            for track in trackController.history.playlist.tracksList {
                if !track.metadataFetched  {
                    fetchMetadata(for: track, wait: true)
                    return
                }
            }
        }
        
        // Else we're done
        self._workerSemaphore.signal()
    }
    
    func fetchMetadata(for track: Track, updating: TrackCellView? = nil, wait: Bool = false) {
        track.metadataFetched = true // So no other thread tries to enter
        
        Library.shared.performInBackground { mox in
            let asyncTrack = mox.convert(track)
            
            asyncTrack.fetchMetadata()
            
            do {
                try mox.save()
            }
            catch let error {
                print(error)
            }
            
            // Update on main thread
            DispatchQueue.main.async {
                track.refresh()
                track.analysis = asyncTrack.analysis
                self.trackController.update(view: updating, with: track)
            }
            
            Thread.sleep(forTimeInterval: TimeInterval(wait ? 0.2 : 0.02))
            
            self._workerSemaphore.signal()
        }
        
    }
}
