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
    return pos > progress ? (sin(pos * size + progress * speed) + 1.0) * 0.3 : 0.2
}

class Analysis {
    static let sampleCount: Int = 500

    var values: [[CGFloat]]?
}

class SPInterpreter {
    static func analyze(file: AVAudioFile, analysis: Analysis) {
        let analyzer = SPAnalyzer()
        
        var lastUpdate: Float = 0.0
        
        let setProgress: (Float) -> Swift.Void = { (progress) in
            var values: [[CGFloat]] = Array(0..<Int(3)).map { (idx) in
                return Array(0..<Analysis.sampleCount).map { sample in
                    let pos = Float(sample) / Float(Analysis.sampleCount)
                    return CGFloat(simulateWave(pos, Float(idx * 15), -23.0 + Float(idx) * 3.0, progress: progress))
                }
            }
            
            let createWave: (Int) -> CGFloat = { (sample) in
                let pos = Float(sample) / Float(Analysis.sampleCount)
                let distance = abs(progress - pos)
                let water = simulateWave(pos, 150.0, 10.0, progress: progress)
                return CGFloat(max(0.7 - distance * 20.0, 0.0) + water * 0.3)
            }
            
            values.insert(Array(0..<Analysis.sampleCount).map(createWave), at: 0)
            
            DispatchQueue.main.async {
                analysis.values = values
            }
        }
        
        analyzer.analyze(file.url) {
            if $0 - lastUpdate < (1.0 / 50) {
                return
            }
            lastUpdate = $0
            
            setProgress($0)
        }
        setProgress(1.0)
        
        let waveformLength: Int = Int(analyzer.waveformSize())
        
        func waveform(start: UnsafeMutablePointer<UInt8>) -> [CGFloat] {
            let raw = Array(UnsafeBufferPointer(start: start, count: waveformLength)).toUInt.toCGFloat
            return Array(0..<Analysis.sampleCount).map { get(raw, at: $0, max: Analysis.sampleCount) }
                .normalized(min: 0.0, max: 255.0)
        }
        
        // This may take a while too
        let wf = waveform(start: analyzer.waveform())
        let lows = waveform(start: analyzer.lowWaveform())

        setProgress(2.0) // Move the wave out of screen

        let mids = waveform(start: analyzer.midWaveform())
        let highs = waveform(start: analyzer.highWaveform())
        

        DispatchQueue.main.async {
            // Normalize waveform but only a little bit
            analysis.values = [wf.normalized(min: 0.0, max: (1.0 + wf.max()!) / 2.0), lows, mids, highs]
        }
    }
}
