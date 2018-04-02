
//
//  ViewController+Background.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
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

extension ViewController {    
    func endTask() {
        self._workerSemaphore.signal()
    }
    
    func startBackgroundTasks() {
        self.visualTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true ) { [unowned self] (timer) in
            guard self.view.window?.isVisible ?? false else {
                return
            }
            
            self._waveformView.setBy(player: self.player)
            
            if !self._timePlayed.isHidden, !self._timeLeft.isHidden {
                self._timePlayed.stringValue = Int(self.player.currentTime).timeString
                self._timeLeft.stringValue = Int(self.player.duration - self.player.currentTime).timeString
            }
        }
        
        self.backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 10.0, repeats: true ) { [unowned self] (timer) in
            if self._workerSemaphore.acquireNow() {
                // Update the current playlist, top priority
                if let desired = self.trackController.desired, desired._changed, desired.semaphore.acquireNow() {
                    desired._changed = false
                    
                    Library.shared.performChildBackgroundTask { mox in
                        let history = desired.playlist?.convert(to: mox) ?=> PlayHistory.init

                        if let history = history {
                            desired.filter ?=> history.filter
                            desired.sort ?=> history.sort
                        }
                        
                        DispatchQueue.main.async {
                            history?.convert(to: Library.shared.viewContext)
                            self.trackController.history = history ?? PlayHistory(playlist: Library.shared.allTracks)
                            self._workerSemaphore.signal()
                            desired.semaphore.signal()
                        }
                    }
                }
                else if let playing = self.playing, playing.analysis == nil {
                    // Analyze the current file
                    self.analyze(track: playing, read: true) {
                        self._workerSemaphore.signal()
                    }
                }
                else if !self.analysisToDo.isEmpty {
                    // Analyze requested file
                    self.analyze(track: self.analysisToDo.removeFirst(), read: false) {
                        self._workerSemaphore.signal()
                    }
                }
                else if (!Library.shared.startExport {
                   self._workerSemaphore.signal()
                }){
                    self.fetchOneMetadata()
                }
            }
        }
        
        // Requests are freaking slow with many tracks so do it rarely
        Timer.scheduledAsyncBlock(withTimeInterval: 10, repeats: true) {
            Library.shared.performChildBackgroundTask { mox in
                let request: NSFetchRequest = Track.fetchRequest()
                request.predicate = NSPredicate(format: "metadataFetched == false")
                self.metadataToDo = Library.shared.viewContext.convert(try! mox.fetch(request))
            }
        }
    }
    
    func fetchOneMetadata() {
        if view.window?.isVisible ?? false {
            for track in trackController.visibleTracks {
                if !track.metadataFetched  {
                    fetchMetadata(for: track)
                    return
                }
            }
            
            if !metadataToDo.isEmpty {
                let track = metadataToDo.removeFirst()
                fetchMetadata(for: track, wait: true) // TODO If we fetched it in the meantime, skip
                return
            }
        }
        
        // Else we're done
        self._workerSemaphore.signal()
    }
    
    func fetchMetadata(for track: Track, wait: Bool = false) {
        track.metadataFetched = true // So no other thread tries to enter
        
        Library.shared.performChildBackgroundTask { mox in
            mox.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

            let asyncTrack = mox.convert(track)
            
            asyncTrack.fetchMetadata()
            
            try! mox.save()
            track.copyTransient(from: asyncTrack)
            
            self._workerSemaphore.signalAfter(seconds: wait ? 0.2 : 0.02)
        }
    }
    
    func analyze(track: Track, read: Bool, completion: @escaping () -> Swift.Void) {
        guard let url = track.url else {
            completion()
            return
        }
        
        track.analysis = Analysis()
        
        if self.playing == track {
            self._waveformView.analysis = track.analysis
        }
        
        self.trackController.reload(track: track) // Get the analysis inside the cell
        
        Library.shared.performChildBackgroundTask { mox in
            mox.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
            
            let asyncTrack = mox.convert(track)
            asyncTrack.analysis = track.analysis
            
            // May exist on disk
            if !read || !asyncTrack.readAnalysis() {
                // TODO Merge with metadata fetch etc
                let audioFile = try! AKAudioFile(forReading: url)
                SPInterpreter.analyze(file: audioFile, analysis: asyncTrack.analysis!)
                asyncTrack.writeAnalysis()
            }
            try! mox.save()
            
            completion()
        }
    }
}
