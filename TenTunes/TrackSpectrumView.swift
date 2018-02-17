//
//  TrackSpectrumView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension ClosedRange {
    public func random() -> Bound {
        let range = (self.upperBound as! CGFloat) - (self.lowerBound as! CGFloat)
        let randomValue = (CGFloat(arc4random_uniform(UINT32_MAX)) / CGFloat(UINT32_MAX)) * range + (self.lowerBound as! CGFloat)
        return randomValue as! Bound
    }
}

class TrackSpectrumView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.lightGray.set() // choose color

        let numBars = Int(self.bounds.width / 5)
        for bar in 0..<Int(self.bounds.width / 5) {
            let figure = NSBezierPath()
            let trackPos = Double(bar) / Double(numBars)
            let height = (sin(CGFloat(trackPos)) + 1) / 2 * 0.5 + (0.0...0.5).random()
            
            figure.move(to: NSMakePoint(CGFloat(bar * 5), height * self.bounds.minY))
            figure.line(to: NSMakePoint(CGFloat(bar * 5), height * self.bounds.maxY))
            
            figure.lineWidth = 3
            figure.stroke()
        }
        
        NSColor.black.set() // choose color
        let p = 0.3
        let position = NSBezierPath()
        
        position.move(to: NSMakePoint(CGFloat(p) * self.bounds.width, self.bounds.minY))
        position.line(to: NSMakePoint(CGFloat(p) * self.bounds.width, self.bounds.maxY))
        
        position.lineWidth = 1
        position.stroke()
    }
    
}
