//
//  ResampleToSize.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.06.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

import Foundation

extension ResampleToSize {
	static func best(data: [Float], toSize count: Int) throws -> [Float] {
		// Don't need to do this here, but doing it avoids some copying
		guard data.count != count else { return data }
		
		return try data.withUnsafeBufferPointer { src in
			let dst = malloc(count * MemoryLayout<Float>.size)!.assumingMemoryBound(to: Float.self)
			
			try best(src.baseAddress!, count: Int32(src.count), dst: dst, count: Int32(count))
			let asArray = Array(UnsafeMutableBufferPointer(start: dst, count: count))

			free(dst)

			return asArray
		}
	}
	
	static func bestOrZero(data: [Float], toSize count: Int) -> [Float] {
		(try? best(data: data, toSize: count)) ?? Array(repeating: 0, count: count)
	}
}
