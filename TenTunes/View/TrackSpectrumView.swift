//
//  TrackSpectrumView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

let sampleCount = 500

class Analysis {
    var file: AVAudioFile

    var values: [[CGFloat]]?
    
    init(file: AVAudioFile) {
        self.file = file
    }
}

func lerp(_ left: [CGFloat], _ right: [CGFloat], _ amount: CGFloat) -> [CGFloat] {
    return zip(left, right).map { (cur, sam) in
        return cur * (CGFloat(1.0) - amount) + sam * amount
    }
}

func get(_ left: [CGFloat], at: Int, max: Int) -> CGFloat {
    let trackPosStart = Double(at) / Double(max + 1)
    let trackPosEnd = Double(at + 1) / Double(max + 1)
    let trackRange = Int(trackPosStart * Double(left.count))...Int(trackPosEnd * Double(left.count))
    
    return left[trackRange].reduce(0, +) / CGFloat(trackRange.count)
}

class TrackSpectrumView: NSControl {
    var location: Double? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var _curValues: [[CGFloat]] = Array(repeating: Array(repeating: CGFloat(0), count: sampleCount), count: 4)
    var _drawValues: [[CGFloat]] { return self.analysis?.values ?? Array(repeating: Array(repeating: CGFloat(0), count: sampleCount), count: 4) }

    var analysis: Analysis? = nil
    
    var timer: Timer? = nil
    
    override func awakeFromNib() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            self._curValues = (0..<4).map { lerp(self._curValues[$0], self._drawValues[$0], CGFloat(1.0 / 30.0)) }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let barWidth = 2
        let segmentWidth = barWidth + 2

        let numBars = Int(self.bounds.width / CGFloat(segmentWidth))

        let values = (0..<4).map { (idx) in
            return Array(0..<numBars).map { get(self._curValues[idx], at: $0, max: numBars) }
        }
        let waveform = values[0], lows = values[1], mids = values[2], highs = values[3]

        for bar in 0..<Int(self.bounds.width / CGFloat(segmentWidth)) {
            let low = lows[bar] * lows[bar], mid = mids[bar] * mids[bar], high = highs[bar] * highs[bar]
            let val = low + mid + high
            
            let h = waveform[bar]

            let figure = NSBezierPath()
            
            // Don't go the full way so we don't loop back to red
            NSColor(hue: (mid / val / 2 + high / val) * 0.8, saturation: CGFloat(0.3), brightness: CGFloat(0.8), alpha: CGFloat(1.0)).set()

            figure.appendRect(NSMakeRect(self.bounds.minX + CGFloat(bar * segmentWidth + 1), self.bounds.minY, CGFloat(barWidth), CGFloat(h * self.bounds.height)))
            
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
    
    func analyze(file: AVAudioFile?) {
        if let file = file {

            self.analysis = Analysis(file: file)

            // Run Async
            DispatchQueue.global(qos: .userInitiated).async {
                let analyzer = SPAnalyzer()
                analyzer.analyze(file.url)
                
                let waveformLength: Int = Int(analyzer.waveformSize())
                
                func waveform(start: UnsafeMutablePointer<UInt8>) -> [CGFloat] {
                    let raw = Array(UnsafeBufferPointer(start: start, count: waveformLength)).toUInt.toCGFloat
                    return Array(0..<sampleCount).map { get(raw, at: $0, max: sampleCount) }
                        .normalized(min: 0.0, max: 255.0)
                }
                
                let wf = waveform(start: analyzer.waveform())
                let lows = waveform(start: analyzer.lowWaveform())
                let mids = waveform(start: analyzer.midWaveform())
                let highs = waveform(start: analyzer.highWaveform())

                DispatchQueue.main.async {
                    if self.analysis?.file != file {
                        return
                    }

                    // Normalize waveform but only a little bit
                    self.analysis!.values = [wf.normalized(min: 0.0, max: (1.0 + wf.max()!) / 2.0), lows, mids, highs]
                }
            }
        }
        else {
            self.analysis = nil
        }
    }    
}
