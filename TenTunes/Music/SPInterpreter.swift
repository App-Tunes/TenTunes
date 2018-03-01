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

func writeCGFloats(_ array: [CGFloat], to url: URL) {
    let wData = Data(bytes: array, count: array.count * MemoryLayout<CGFloat>.stride)
    try! wData.write(to: url)
}

func readCGFloats(from: URL) -> [CGFloat]? {
    if let data = try? Data(contentsOf: from) {
        return data.withUnsafeBytes { (bytes: UnsafePointer<CGFloat>) in
            return Array(UnsafeBufferPointer(start: bytes, count: data.count / MemoryLayout<CGFloat>.size))
        }
    }
    return nil
}

class Analysis {
    static let sampleCount: Int = 500

    var values: [[CGFloat]] = Array(repeating: Array(repeating: 0.0, count: sampleCount), count: 4)
    var complete = false
    
    func write(url: URL) {
        writeCGFloats(values[0], to: url.appendingPathComponent("wave"))
        writeCGFloats(values[1], to: url.appendingPathComponent("low"))
        writeCGFloats(values[2], to: url.appendingPathComponent("mid"))
        writeCGFloats(values[3], to: url.appendingPathComponent("high"))
    }
    
    static func read(url: URL) -> Analysis? {
        let wave = readCGFloats(from: url.appendingPathComponent("wave"))
        let low = readCGFloats(from: url.appendingPathComponent("low"))
        let mid = readCGFloats(from: url.appendingPathComponent("mid"))
        let high = readCGFloats(from: url.appendingPathComponent("high"))

        if let wave = wave, let low = low, let mid = mid, let high = high {
            let analysis = Analysis()
            analysis.values = [wave, low, mid, high]
            return analysis
        }
        return nil
    }
}

class SPInterpreter {
    static func analyze(file: AVAudioFile, analysis: Analysis) {
        let analyzer = SPAnalyzer()
        
        let previewSamplesTotal = 20000
        var currentSamples = 0
        // Pre-init for performance
        var floats: [CGFloat] = Array(repeating: CGFloat(0), count: previewSamplesTotal)

        let setProgress: (Float) -> Swift.Void = { (progress) in
            let time = Float(CACurrentMediaTime().truncatingRemainder(dividingBy: 1000)) // Allow for accuracy
            
            var values: [[CGFloat]] = Array(0..<Int(3)).map { (idx) in
                return Array(0..<Analysis.sampleCount).map { sample in
                    let pos = Float(sample) / Float(Analysis.sampleCount)
                    return CGFloat(simulateWave(pos, Float(idx * 10), -8.0 + Float(idx), progress: progress, time: time))
                }
            }
            
            let createWave: (Int) -> CGFloat = { (sample) in
                // Move the wave out of screen at the end and start
                let pos = Float(sample) / Float(Analysis.sampleCount) * 0.95 + 0.025
                let distance = abs(progress - pos)
                let water = simulateWave(pos, 100.0, 5.0, progress: progress, time: time)
                return CGFloat(max(0.7 - distance * 20.0, 0.0) + water * 0.3)
            }
            
            let waveIndex = min(Int(progress * Float(Analysis.sampleCount)), Analysis.sampleCount)
            let approxWave = floats[0..<currentSamples].remap(toSize: waveIndex)
            values.insert(Array(0..<Analysis.sampleCount).map {createWave($0) + ($0 < waveIndex ? approxWave[$0] : 0.0)}, at: 0)
            
            DispatchQueue.main.async {
                analysis.values = values
            }
        }
        
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
        
        let waveformLength: Int = Int(analyzer.waveformSize())
        
        func waveform(start: UnsafeMutablePointer<UInt8>) -> [CGFloat] {
            let raw = Array(UnsafeBufferPointer(start: start, count: waveformLength)).toUInt.toCGFloat
            return raw.remap(toSize: Analysis.sampleCount).normalized(min: 0.0, max: 255.0)
        }
        
        // This may take a while too
        // So move the wave a little further
        let wf = waveform(start: analyzer.waveform())
        setProgress(1.03)
        let lows = waveform(start: analyzer.lowWaveform())
        setProgress(1.06)
        let mids = waveform(start: analyzer.midWaveform())
        setProgress(1.09)
        let highs = waveform(start: analyzer.highWaveform())
        setProgress(1.12)
        
        DispatchQueue.main.async {
            // Normalize waveform but only a little bit
            analysis.values = [wf.normalized(min: 0.0, max: (1.0 + wf.max()!) / 2.0), lows, mids, highs]
            analysis.complete = true
        }
    }
}
