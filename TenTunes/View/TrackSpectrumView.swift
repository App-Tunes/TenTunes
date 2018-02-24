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

    var lows: [CGFloat]?
    var mids: [CGFloat]?
    var highs: [CGFloat]?
    
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
    
    var _curLows: [CGFloat] = Array(repeating: CGFloat(0), count: sampleCount)
    var _curMids: [CGFloat] = Array(repeating: CGFloat(0), count: sampleCount)
    var _curHighs: [CGFloat] = Array(repeating: CGFloat(0), count: sampleCount)

    var _drawLows: [CGFloat] { return self.analysis?.lows ?? Array(repeating: CGFloat(0), count: sampleCount) }
    var _drawMids: [CGFloat] { return self.analysis?.mids ?? Array(repeating: CGFloat(0), count: sampleCount) }
    var _drawHighs: [CGFloat] { return self.analysis?.highs ?? Array(repeating: CGFloat(0), count: sampleCount) }

    var analysis: Analysis? = nil
    
    var timer: Timer? = nil
    
    override func awakeFromNib() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            self._curLows = lerp(self._curLows, self._drawLows, CGFloat(1.0 / 30.0))
            self._curMids = lerp(self._curMids, self._drawMids, CGFloat(1.0 / 30.0))
            self._curHighs = lerp(self._curHighs, self._drawHighs, CGFloat(1.0 / 30.0))
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let barWidth = 2
        let segmentWidth = barWidth + 2

        let numBars = Int(self.bounds.width / CGFloat(segmentWidth))

        let lows = Array(0..<numBars).map { get(self._curLows, at: $0, max: numBars) }
        let mids = Array(0..<numBars).map { get(self._curMids, at: $0, max: numBars) }
        let highs = Array(0..<numBars).map { get(self._curHighs, at: $0, max: numBars) }

        for bar in 0..<Int(self.bounds.width / CGFloat(segmentWidth)) {
            let low = lows[bar] * lows[bar], mid = mids[bar] * mids[bar], high = highs[bar] * highs[bar]
            let val = low + mid + high
            
            let h = lows[bar] + mids[bar] + highs[bar]

            let figure = NSBezierPath()
            
            NSColor(hue: (mid / val / 2 + high / val) * 0.6, saturation: CGFloat(0.3), brightness: CGFloat(0.8), alpha: CGFloat(1.0)).set()

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
                
                let lows = waveform(start: analyzer.lowWaveform())
                let mids = waveform(start: analyzer.midWaveform())
                let highs = waveform(start: analyzer.highWaveform())

                DispatchQueue.main.async {
                    if self.analysis?.file != file {
                        return
                    }

                    self.analysis!.lows = lows
                    self.analysis!.mids = mids
                    self.analysis!.highs = highs
                }
            }
        }
        else {
            self.analysis = nil
        }
    }    
}
