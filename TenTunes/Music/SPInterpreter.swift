//
//  SPInterpreter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation

class Analysis {
    var values: [[CGFloat]]?
}

class SPInterpreter {
    static func analyze(file: AVAudioFile, analysis: Analysis) {
        let analyzer = SPAnalyzer()
        analyzer.analyze(file.url)
        
        let waveformLength: Int = Int(analyzer.waveformSize())
        
        func waveform(start: UnsafeMutablePointer<UInt8>) -> [CGFloat] {
            let raw = Array(UnsafeBufferPointer(start: start, count: waveformLength)).toUInt.toCGFloat
            return Array(0..<sampleCount).map { get(raw, at: $0, max: sampleCount) }
                .normalized(min: 0.0, max: 255.0)
        }
        
        let wf = waveform(start: analyzer.waveform())
        let lows = waveform(start: analyzer.lowWaveform())
        let mids = waveform(start: analyzer.midWaveform())
        let highs = waveform(start: analyzer.highWaveform())
        
        DispatchQueue.main.async {
            // Normalize waveform but only a little bit
            analysis.values = [wf.normalized(min: 0.0, max: (1.0 + wf.max()!) / 2.0), lows, mids, highs]
        }
    }
}
