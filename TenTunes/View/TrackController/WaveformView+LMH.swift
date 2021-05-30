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
		
		let pitch: [CGFloat] = (0 ..< values.waveform.count).map {
			// Color
			let low = values.lows[$0] * values.lows[$0]
			let mid = values.mids[$0] * values.mids[$0]
			let high = values.highs[$0] * values.highs[$0]
			
			let val = low + mid + high
			return mid / val / 2 + high / val
		}

		return Waveform(loudness: values.waveform.map(Float.init), pitch: pitch.map(Float.init))
	}
}
