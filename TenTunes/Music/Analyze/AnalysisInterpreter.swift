//
//  SPInterpreter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation

func simulateWave(_ pos: Float, _ size: Float, _ speed: Float, progress: Float, time: Float) -> Float {
    return (sin(pos * size + time * speed) + 1.0) * (pos > progress ? 0.3 : 0.05) + (pos > progress ? 0.1 : 0.35)
}

class AnalysisInterpreter {
    struct Flags: OptionSet {
        let rawValue: Int
        
        static let speed = Flags(rawValue: 1 << 0)
        static let key = Flags(rawValue: 1 << 1)
    }
    
    static func analyze(file: AVAudioFile, track: Track, flags: Flags = []) {
        let analysis = track.analysis!
        let analyzer = TTAudioKitAnalyzer()
        
        let previewSamplesTotal = 20000
        var currentSamples = 0
        // Pre-init for performance
        var floats: [CGFloat] = Array(repeating: CGFloat(0), count: previewSamplesTotal)

        let setProgress: (Float) -> Swift.Void = { (progress) in }
        
        var lastUpdate: CFTimeInterval = CACurrentMediaTime()
        
        setProgress(0.0)

        analyzer.analyze(file.url) { (progress, buffer, count) in
            // Sometimes this can get called with progress > 1
            let desiredAmount = min(min(Int(progress * Float(previewSamplesTotal)), previewSamplesTotal) - currentSamples, Int(count))
            if desiredAmount > 0 {
                let newFloats = Array(UnsafeBufferPointer(start: buffer, count: desiredAmount))
                for i in 0..<desiredAmount {
                    floats[i + currentSamples] = abs(CGFloat(newFloats[i])) * 1.4 // Roughly this value makes most things more accurate apparently
                }
                currentSamples += desiredAmount
            }

            let thisUpdate = CACurrentMediaTime()
            if thisUpdate - lastUpdate < (1.0 / 20.0) { // 20 fps
                return
            }
            lastUpdate = thisUpdate

            setProgress(progress)
        }
        
        setProgress(1.0)
        
        guard !analyzer.failed else {
            analysis.values = nil
            analysis.complete = true
            return
        }
        
        let waveformLength: Int = Int(analyzer.waveformSize)
        
        func waveform(start: UnsafeMutablePointer<UInt8>) -> [CGFloat] {
            let raw = Array(UnsafeBufferPointer(start: start, count: waveformLength)).toUInt.toCGFloat
            return raw.rms(toSize: Analysis.sampleCount).normalized(min: 0.0, max: 255.0)
        }
        
        // This may take a while too
        // So move the wave a little further
        var wf = waveform(start: analyzer.averageWaveform)
        setProgress(1.03)
        wf = wf.normalized(min: 0.0, max: wf.max()!, clamp: true)
        wf = wf.map { pow($0, 1.5) }  // Make it exponential-ish (lol)
        setProgress(1.06)
        var lows = waveform(start: analyzer.lowWaveform)
        lows = lows.map { pow($0, 1.5) }
        setProgress(1.09)
        var mids = waveform(start: analyzer.midWaveform)
        mids = mids.map { pow($0, 1.5) }
        setProgress(1.12)
        var highs = waveform(start: analyzer.highWaveform)
        highs = highs.map {pow($0, 1.5) }
        
        // Normalize waveform but only a little bit
        analysis.values = .init(waveform: wf, lows: lows, mids: mids, highs: highs)
        analysis.complete = true
        
        // TODO Also use peakDecibel for a cap?
        track.loudness = -12 / analyzer.loudpartsAverageDecibel

        if flags.contains(.speed) {
            track.speed = Track.Speed(beatsPerMinute: Double(analyzer.bpm))
        }
        
        if flags.contains(.key) {
            // Set rKey since only the Key class decides how the user wants to write his keys
            track.key = Key.parse(analyzer.initialKey)
        }
    }
}
