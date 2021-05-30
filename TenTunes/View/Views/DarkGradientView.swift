//
//  DarkGradientLayer.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 30.05.21.
//  Copyright © 2021 ivorius. All rights reserved.
//

import Cocoa

class DarkGradientView {
	static func make() -> NSView {
		let layer = CAGradientLayer()
		
		layer.actions = [
			"onOrderOut": NSNull(),
			"onOrderIn": NSNull(),
			"sublayers": NSNull(),
			"contents": NSNull(),
			"bounds": NSNull(),
		]
		
		let gradientSteps = 10
		layer.colors = (0 ... gradientSteps).reversed().map {
			NSColor.black.withAlphaComponent(CGFloat($0) * 0.5 / CGFloat(gradientSteps)).cgColor
		}
		// "Ease In"
		layer.locations = (0 ... gradientSteps).map { NSNumber(value: pow(Double($0) / Double(gradientSteps), 2)) }
		layer.zPosition = -2
				
		let gradientView = NSView()
		gradientView.translatesAutoresizingMaskIntoConstraints = false
		gradientView.wantsLayer = true
		gradientView.layer = layer
		
		return gradientView
	}
}
