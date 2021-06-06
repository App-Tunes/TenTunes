//
//  WaveformView+LMH.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.05.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

import TunesUI

extension Waveform {
	static func from(_ values: Analysis.Values?) -> Waveform {
		guard let values = values else {
			return .empty
		}
		
		return Waveform(
			loudness: values.loudness,
			pitch: values.pitch
		)
	}
	
	static func from(_ waveform: EssentiaWaveform) -> Waveform {
		let wmax = waveform.integratedLoudness + 6
		let wmin = waveform.integratedLoudness - waveform.loudnessRange - 6
		let range = wmax - wmin

		return Waveform.init(
			loudness: Array(UnsafeBufferPointer(start: waveform.loudness, count: Int(waveform.count)))
				.map { max(0, min(1, ($0 - wmin) / range)) }, // In LUFS. 23 is recommended standard. We'll use -40 as absolute 0.
			pitch: Array(UnsafeBufferPointer(start: waveform.pitch, count: Int(waveform.count)))
				.map { max(0, min(1, (log(max(10, $0) / 3000) + 2) / 2)) }  // in frequency space: log(40 / 3000) ~ -2
		)
	}
}

extension WaveformView {
	static let activeFPS: Double = 10
}
