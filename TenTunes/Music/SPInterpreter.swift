//
//  SPInterpreter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation

func simulateWave(_ pos: Float, _ size: Float, _ speed: Float, progress: Float) -> Float {
    return (sin(pos * size + progress * speed) + 1.0) * (pos > progress ? 0.3 : 0.05) + (pos > progress ? 0.1 : 0.35)
}

class Analysis {
    static let sampleCount: Int = 500

    var values: [[CGFloat]]?
}

class SPInterpreter {
    static func analyze(file: AVAudioFile, analysis: Analysis) {
        let analyzer = SPAnalyzer()
        
        var floats: [CGFloat] = []
        
        let setProgress: (Float) -> Swift.Void = { (progress) in
            var values: [[CGFloat]] = Array(0..<Int(3)).map { (idx) in
                return Array(0..<Analysis.sampleCount).map { sample in
                    let pos = Float(sample) / Float(Analysis.sampleCount)
                    return CGFloat(simulateWave(pos, Float(idx * 15), -23.0 + Float(idx) * 3.0, progress: progress))
                }
            }
            
            let createWave: (Int) -> CGFloat = { (sample) in
                // Move the wave out of screen at the end and start
                let pos = Float(sample) / Float(Analysis.sampleCount) * 0.9 + 0.05
                let distance = abs(progress - pos)
                let water = simulateWave(pos, 150.0, 10.0, progress: progress)
                return CGFloat(max(0.7 - distance * 20.0, 0.0) + water * 0.3)
            }
            
            let waveIndex = min(Int(progress * Float(Analysis.sampleCount)), Analysis.sampleCount)
            let approxWave = floats.remap(toSize: waveIndex)
            values.insert(Array(0..<Analysis.sampleCount).map {createWave($0) + ($0 < waveIndex ? approxWave[$0] : 0.0)}, at: 0)
            
            DispatchQueue.main.async {
                analysis.values = values
            }
        }
        
        var lastUpdate: TimeInterval = NSDate().timeIntervalSince1970
        
        setProgress(0.0)

        analyzer.analyze(file.url) { (progress, buffer, count) in
            let newFloats = Array(UnsafeBufferPointer(start: buffer, count: Int(count / 2000 + 1)))
            floats += newFloats.toCGFloat.map(abs).map { $0 * 1.4 } // About this makes most things more accurate apparently

            let thisUpdate = NSDate().timeIntervalSince1970
            if thisUpdate - lastUpdate < (1.0 / 20.0) { // 20 fps
                return
            }
            lastUpdate = thisUpdate

            setProgress(progress)
        }
        
        setProgress(1.0)
        
        let waveformLength: Int = Int(analyzer.waveformSize())
        
        func waveform(start: UnsafeMutablePointer<UInt8>) -> [CGFloat] {
            let raw = Array(UnsafeBufferPointer(start: start, count: waveformLength)).toUInt.toCGFloat
            return raw.remap(toSize: Analysis.sampleCount).normalized(min: 0.0, max: 255.0)
        }
        
        // This may take a while too
        let wf = waveform(start: analyzer.waveform())
        let lows = waveform(start: analyzer.lowWaveform())

        setProgress(1.1) // Move the wave out of screen

        let mids = waveform(start: analyzer.midWaveform())
        let highs = waveform(start: analyzer.highWaveform())
        
        DispatchQueue.main.async {
            // Normalize waveform but only a little bit
            analysis.values = [wf.normalized(min: 0.0, max: (1.0 + wf.max()!) / 2.0), lows, mids, highs]
        }
    }
}
