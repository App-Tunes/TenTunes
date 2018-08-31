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
    
    override func spawn(running: [Task]) -> Task? {
        if let playing = ViewController.shared.player.playing {
            return AnalyzeTrack(track: playing, read: true, priority: 1)
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
    
    override func eq(other: Task) -> Bool {
        return (other as! TrackTask).track == track
    }
}

class AnalyzeTrack: TrackTask {
    var read: Bool
    var analyzeFlags: SPInterpreter.Flags
    
    init(track: Track, read: Bool, analyzeFlags: SPInterpreter.Flags = [], priority: Float = 20) {
        self.read = read
        self.analyzeFlags = analyzeFlags
        super.init(track: track, priority: priority)
    }
        
    override var title: String { return analyzeFlags.isEmpty ? "Analyze Track" : "Analyze Track Metadata" }
    
    // If not read we were specifically asked to re-analyze
    override var preventsQuit: Bool { return !read }

    override func execute() {
        self.analyze(read: read) {
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
            
            guard let asyncTrack = mox.convert(self.track) else {
                completion()
                return
            }
            
            asyncTrack.analysis = self.track.analysis
            
            // May exist on disk
            if !read || !asyncTrack.readAnalysis() {
                // TODO Merge with metadata fetch etc
                let audioFile = try! AKAudioFile(forReading: url)
                SPInterpreter.analyze(file: audioFile, track: asyncTrack, flags: self.analyzeFlags)
                
                asyncTrack.writeAnalysis()

                try! asyncTrack.writeMetadata(values: self.analyzeFlags.components.compactMap {
                    switch $0 {
                    case SPInterpreter.Flags.key:
                        return \Track.keyString
                    case SPInterpreter.Flags.speed:
                        return \Track.bpmString
                    default:
                        return nil
                    }
                })
            }
            try! mox.save()
            
            completion()
        }
    }
    
    override func eq(other: Task) -> Bool {
        let other = other as! AnalyzeTrack
        return super.eq(other: other) && read == other.read && analyzeFlags == other.analyzeFlags
    }
}
