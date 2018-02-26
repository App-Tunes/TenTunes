//
//  TrackSpectrumView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

func lerp(_ left: [CGFloat], _ right: [CGFloat], _ amount: CGFloat) -> [CGFloat] {
    return zip(left, right).map { (cur, sam) in
        return cur * (CGFloat(1.0) - amount) + sam * amount
    }
}

class TrackSpectrumView: NSControl {
    var location: Double? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var _curValues: [[CGFloat]] = Array(repeating: Array(repeating: CGFloat(0), count: Analysis.sampleCount), count: 4)
    var _drawValues: [[CGFloat]] { return self.analysis?.values ?? Array(repeating: Array(repeating: CGFloat(0), count: Analysis.sampleCount), count: 4) }

    var analysis: Analysis? = nil
    
    var timer: Timer? = nil
    
    override func awakeFromNib() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            self._curValues = (0..<4).map { lerp(self._curValues[$0], self._drawValues[$0], CGFloat(1.0 / 5.0)) }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let barWidth = 2
        let segmentWidth = barWidth + 2

        let numBars = Int(self.bounds.width / CGFloat(segmentWidth))

        let values = _curValues.map { wf in wf.remap(toSize: numBars) }
        let waveform = values[0], lows = values[1], mids = values[2], highs = values[3]
        
        let start = bounds.minX + (bounds.width - CGFloat(numBars * segmentWidth)) / 2

        let bg = NSBezierPath()
        bg.appendRect(self.bounds)
        let bgGradient = NSGradient(starting: NSColor.black.withAlphaComponent(0.4), ending: NSColor.clear)
        bgGradient?.draw(in: bg, angle: 90)

        for bar in 0..<numBars {
            let low = lows[bar] * lows[bar], mid = mids[bar] * mids[bar], high = highs[bar] * highs[bar]
            let val = low + mid + high
            
            let h = waveform[bar]

            let figure = NSBezierPath()
            
            // Don't go the full way so we don't loop back to red
            NSColor(hue: (mid / val / 2 + high / val) * 0.8, saturation: CGFloat(0.3), brightness: CGFloat(0.8), alpha: CGFloat(1.0)).set()

            figure.appendRect(NSMakeRect(start + CGFloat(bar * segmentWidth) + 1, self.bounds.minY, CGFloat(barWidth), CGFloat(h * self.bounds.height)))
            
            figure.fill()
        }
        
        if let location = self.location {
            NSColor.white.set() // choose color
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
        self.location = (0.0...1.0).clamp(Float(at.x) / Float(self.bounds.width))
        
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

import AudioKit
import AudioKitUI

extension TrackSpectrumView {
    func setBy(player: AKPlayer) {
        if player.audioFile != nil {
            self.setBy(time: player.currentTime, max: player.duration)
        }
        else {
            self.location = nil
        }
    }
    
    func setBy(time: Double, max: Double) {
        self.location = time / max
    }
    
    func getBy(player: AKPlayer) -> Double? {
        return player.audioFile != nil ? self.getBy(max: player.duration) : nil
    }

    func getBy(max: Double) -> Double? {
        return self.location != nil ? self.location! * max : nil
    }
}
