//
//  SPInterpreter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation
import TunesUI

func simulateWave(_ pos: Float, _ size: Float, _ speed: Float, progress: Float, time: Float) -> Float {
    return (sin(pos * size + time * speed) + 1.0) * (pos > progress ? 0.3 : 0.05) + (pos > progress ? 0.1 : 0.35)
}

class AnalysisInterpreter {
	/// Unfortunately, essentia seems not to be threadsafe just now
	static let essentiaWork = DispatchSemaphore(value: 1)

    struct Flags: OptionSet {
        let rawValue: Int
        
        static let speed = Flags(rawValue: 1 << 0)
        static let key = Flags(rawValue: 1 << 1)
    }
    
    static func analyze(file: AVAudioFile, track: Track, flags: Flags = []) {
		essentiaWork.wait()
		defer { essentiaWork.signal() }
		
        let analysis = track.analysis!
        		
		let file = EssentiaFile(url: file.url)
		
		guard let results = try? file.analyzeWaveform(Int32(Analysis.sampleCount)) else {
			analysis.values = nil
			analysis.complete = true
			return
		}

		let waveform = Waveform.from(results)
		
		analysis.values = .init(
			loudness: waveform.loudness,
			pitch: waveform.pitch
		)
		analysis.complete = true
		track.loudness = results.integratedLoudness

		// TODO Speed / Key
//        if flags.contains(.speed) {
//            track.speed = Track.Speed(beatsPerMinute: Double(analyzer.bpm))
//        }
//
//        if flags.contains(.key) {
//            // Set rKey since only the Key class decides how the user wants to write his keys
//            track.key = Key.parse(analyzer.initialKey)
//        }
    }
}
