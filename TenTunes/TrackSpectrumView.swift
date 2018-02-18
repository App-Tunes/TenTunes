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

class TrackSpectrumView: NSControl {

    var location: Float? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var samples: [CGFloat]? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.lightGray.set() // choose color

        if let samples = self.samples {
            let numBars = Int(self.bounds.width / 5)
            for bar in 0..<Int(self.bounds.width / 5) {
                let figure = NSBezierPath()
                let trackPos = Double(bar) / Double(numBars)
                let height = samples[Int(trackPos * Double(samples.count))]
                
                figure.move(to: NSMakePoint(CGFloat(bar * 5), height * self.bounds.minY))
                figure.line(to: NSMakePoint(CGFloat(bar * 5), height * self.bounds.maxY))
                
                figure.lineWidth = 3
                figure.stroke()
            }
        }
        
        if let location = self.location {
            NSColor.black.set() // choose color
            let position = NSBezierPath()
            
            position.move(to: NSMakePoint(CGFloat(location) * self.bounds.width, self.bounds.minY))
            position.line(to: NSMakePoint(CGFloat(location) * self.bounds.width, self.bounds.maxY))
            
            position.lineWidth = 1
            position.stroke()
        }
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    func click(at: NSPoint) {
        self.location = Float(at.x) / Float(self.bounds.width)
        
        if let action = self.action, let target = self.target {
            NSApp.sendAction(action, to: target, from: self)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.click(at: self.convert(event.locationInWindow, from: nil))
    }
    
    override func mouseDown(with event: NSEvent) {
        self.click(at: self.convert(event.locationInWindow, from: nil))
    }
}

import AVFoundation

extension TrackSpectrumView {
    func setBy(player: AVPlayer) {
        self.setBy(time: player.currentTime(), max: player.currentItem!.asset.duration)
    }
    
    func setBy(time: CMTime, max: CMTime) {
        self.location = Float(CMTimeGetSeconds(time) / CMTimeGetSeconds(max))
    }
    
    func getBy(player: AVPlayer) -> CMTime {
        return self.getBy(max: player.currentItem!.asset.duration)
    }

    func getBy(max: CMTime) -> CMTime {
        return CMTimeMultiplyByFloat64(max, Float64(self.location!))
    }
    
    func analyze(player: AVPlayer?, samples: Int) {
        if let player = player {
            self.samples = []
            for i in 0..<samples {
                let trackPos = Double(i) / Double(samples)
                let val = CGFloat((sin(CGFloat(trackPos) * 15) + 1) / 2 * 0.5 + (sin(CGFloat(trackPos) * 5) + 1) / 2 * 0.5)
                self.samples!.append(val)
            }
        }
        else {
            self.samples = nil
        }
    }
}
