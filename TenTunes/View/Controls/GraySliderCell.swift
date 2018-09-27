
//
//  TintableSliderCell.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class GraySliderCell: NSSliderCell {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let barRadius = CGFloat(2.5)
        let value = CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue))
        let finalWidth = CGFloat(value * (self.controlView!.frame.size.width - 8))
        var leftRect = rect
        leftRect.size.width = finalWidth
        
        NSColor.tertiaryLabelColor.setFill()
        NSBezierPath(roundedRect: leftRect, xRadius: barRadius, yRadius: barRadius).fill()
        
        NSColor.controlAlternatingRowBackgroundColors[1].setFill()
        NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius).fill()
    }
}
