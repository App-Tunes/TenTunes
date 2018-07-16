//
//  AnalyzeCurrentTrack.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AudioKit

class AnalyzeCurrentTrack: Tasker {
    override var promise: Float? {
        if let playing = ViewController.shared.player.playing, playing.analysis == nil {
            return 0.5
        }
        
        return nil
    }
    
    override func spawn() -> Task? {
        if let playing = ViewController.shared.player.playing {
            return AnalyzeTrack(track: playing, priority: 1)
        }
        
        return nil
    }
}

class TrackTask: Task {
    var track: Track

    init(track: Track, priority: Float = 1) {
        self.track = track
        super.init(priority: priority)
    }
}

extension TrackTask : SameObjective {
    static func objectivesEqual(lhs: TrackTask, rhs: TrackTask) -> Bool {
        return lhs.track == rhs.track
    }
}

class AnalyzeTrack: TrackTask {
    override init(track: Track, priority: Float = 20) {
        super.init(track: track, priority: priority)
    }
        
    override var title: String { return "Analyze Track" }

    override func execute() {
        self.analyze(read: true) {
            self.finish()
        }
    }
    
    func analyze(read: Bool, completion: @escaping () -> Swift.Void) {
        guard let url = track.url else {
            completion()
            return
        }
        
        track.analysis = Analysis()
        
        if ViewController.shared.player.playing == track {
            ViewController.shared._waveformView.analysis = track.analysis
        }
        
        ViewController.shared.trackController.reload(track: track) // Get the analysis inside the cell
        
        Library.shared.performChildBackgroundTask { mox in
            mox.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
            
            let asyncTrack = mox.convert(self.track)
            asyncTrack.analysis = self.track.analysis
            
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
