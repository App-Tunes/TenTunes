//
//  TrackSpectrumView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

let sampleCount = 200

extension ClosedRange {
    public func random() -> Bound {
        let range = (self.upperBound as! CGFloat) - (self.lowerBound as! CGFloat)
        let randomValue = (CGFloat(arc4random_uniform(UINT32_MAX)) / CGFloat(UINT32_MAX)) * range + (self.lowerBound as! CGFloat)
        return randomValue as! Bound
    }
}

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle(seed: Int) {
        let c = count
        guard c > 1 else { return }
        
        srand48(seed)
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(Int(drand48() * Double(Int(unshuffledCount))))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

func analyze(file: AVAudioFile?, shift: Int, values: [CGFloat]?) -> [CGFloat]? {
    guard let file = file, var values = values else {
        return nil
    }
    
    let startPos = file.framePosition
    
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)!
    
    let readSamples = AVAudioFrameCount(1)
    let skipSamples = AVAudioFrameCount(Int(file.length) / values.count - 1)
    
    let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(readSamples))!
    
    // Shuffle order to hopefully speed up result accuracy
    var order = Array(0...skipSamples)
    order.shuffle(seed: 42)
    file.framePosition = Int64(order[shift])

    for i in 0..<values.count {
        do {
            try file.read(into: buf, frameCount: readSamples)
        }
        catch let error {
            print(error.localizedDescription)
            return nil
        }
        
        let floatValues = Array(UnsafeBufferPointer(start: buf.floatChannelData?[0], count:Int(buf.frameLength)))
        file.framePosition += Int64(skipSamples)
        
        let val = CGFloat(floatValues.map(abs).reduce(0, +)) / CGFloat(floatValues.count)
        
        if shift > 0 {
            values[i] = values[i] / CGFloat(shift + 1) * CGFloat(shift)
        }
        values[i] += val / CGFloat(shift + 1)
    }
    
    file.framePosition = startPos
    
    return values
}

class TrackSpectrumView: NSControl {

    var location: Double? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var curSamples: [CGFloat] = Array(repeating: CGFloat(0), count: sampleCount) {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var _drawSamples: [CGFloat] { return self.samples ?? Array(repeating: CGFloat(0), count: sampleCount) }
    
    var samples: [CGFloat]? = nil
    
    var audioFile: AVAudioFile? = nil
    
    var timer: Timer? = nil
    
    override func awakeFromNib() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            let drawSamples = self._drawSamples
            
            self.curSamples = zip(self.curSamples, drawSamples).map { (cur, sam) in
                return cur * CGFloat(29.0 / 30.0) + sam / CGFloat(30.0) // .5 second lerp
            }

            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.lightGray.set() // choose color
        
        let samples = self.curSamples
    
        var bars: [CGFloat] = []

        let numBars = Int(self.bounds.width / 5)
        for bar in 0..<Int(self.bounds.width / 5) {
            let trackPosStart = Double(bar) / Double(numBars + 1)
            let trackPosEnd = Double(bar + 1) / Double(numBars + 1)
            let trackRange = Int(trackPosStart * Double(samples.count))...Int(trackPosEnd * Double(samples.count))
            
            bars.append(samples[trackRange].reduce(0, +) / CGFloat(trackRange.count))
        }
        
        let samplesMax = max(samples.max()!, 0.2) // Make sure if it goes against 0 it does go
        bars = bars.map {$0 / samplesMax}

        for bar in 0..<Int(self.bounds.width / 5) {
            let val = bars[bar]

            let figure = NSBezierPath()

            figure.move(to: NSMakePoint(CGFloat(bar * 5), val * self.bounds.minY))
            figure.line(to: NSMakePoint(CGFloat(bar * 5), val * self.bounds.maxY))
            
            figure.lineWidth = 3
            figure.stroke()
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
        self.audioFile = file
        self.samples = nil
        
        if let file = file {
            // Run Async
            DispatchQueue.global(qos: .userInitiated).async {
                var samples: [CGFloat]? = Array(repeating: CGFloat(0), count: sampleCount)
                
                for i in 0..<sampleCount {
                    samples = TenTunes.analyze(file: file, shift: i, values: samples)
                    
                    if self.audioFile != file {
                        return
                    }
                    
                    // Update on main thread
                    DispatchQueue.main.async {
                        self.samples = samples
                    }
                }
            }
        }
    }    
}
