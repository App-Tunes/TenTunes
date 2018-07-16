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
            return AnalyzeTrack(track: playing)
        }
        
        return nil
    }
}

class AnalyzeTrack: Task {
    var track: Track
    
    init(track: Track) {
        self.track = track
    }
    
    override var priority: Float { return 1 }
    
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
