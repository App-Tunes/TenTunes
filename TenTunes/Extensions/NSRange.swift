//
//  NSRange.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 06.06.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

import Foundation

extension NSRange {
	var asRange: Range<Int> { lowerBound ..< upperBound }
}
