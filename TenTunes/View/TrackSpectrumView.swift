//
//  TrackSpectrumView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import QuartzCore

func lerp(_ left: [CGFloat], _ right: [CGFloat], _ amount: CGFloat) -> [CGFloat] {
    return zip(left, right).map { (cur, dest) in
        if amount >= 1 { return dest }
        else if amount <= 0 { return cur }
        
        return cur * (CGFloat(1.0) - amount) + dest * amount
    }
}

class BarsLayer: CALayer {
    static var defaultValues: [[CGFloat]] {
        return Array(repeating: Array(repeating: 0.0, count: Analysis.sampleCount), count: 4)
    }
    
    var values: [[CGFloat]] = defaultValues {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init() {
        super.init()
        needsDisplayOnBoundsChange = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        needsDisplayOnBoundsChange = true
    }
    
    override func draw(in ctx: CGContext) {
        let barWidth = 2
        let segmentWidth = barWidth + 2

        let numBars = Int(frame.width / CGFloat(segmentWidth))
        
        let values = self.values.map { wf in wf.remap(toSize: numBars) }
        let waveform = values[0], lows = values[1], mids = values[2], highs = values[3]

        let start = frame.minX + (frame.width - CGFloat(numBars * segmentWidth)) / 2

        for idx in 0..<numBars {
            // Frame
            let h = waveform[idx]

            let rect = CGRect(
                x: start + CGFloat(idx * segmentWidth) + 1,
                y: frame.minY,
                width: CGFloat(barWidth),
                height: CGFloat(h * frame.height)
            )
            
            // Color
            let low = lows[idx] * lows[idx], mid = mids[idx] * mids[idx], high = highs[idx] * highs[idx]
            let val = low + mid + high
            
            // Don't go the full way so we don't loop back to red
            let color = NSColor(hue: (mid / val / 2 + high / val) * 0.8, saturation: CGFloat(0.3), brightness: CGFloat(0.8), alpha: CGFloat(1.0)).cgColor

            ctx.setFillColor(color)
            ctx.fill(rect)
        }
    }
}

class TrackSpectrumView: NSControl, CALayerDelegate {
    var location: Double? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var _barsLayer: BarsLayer!
    var _positionLayer: CALayer!
    var _mousePositionLayer: CALayer!
    var _bgLayer: CAGradientLayer!

    var analysis: Analysis? = nil {
        didSet {
            transitionSteps = self.completeTransitionSteps
        }
    }
    
    var timer: Timer? = nil
    
    var transitionSteps = 0
    
    var updateTime = 1.0 / 30.0
    var lerpRatio = CGFloat(1.0 / 5.0)
    var completeTransitionSteps = 120

    override func awakeFromNib() {
        self.wantsLayer = true
        self.layer = CALayer()
        self.layer!.delegate = self
        self.layer!.needsDisplayOnBoundsChange = true

        _bgLayer = CAGradientLayer()
        _bgLayer.colors = [
            NSColor.black.withAlphaComponent(0.4),
            NSColor.clear
        ]
        _bgLayer.zPosition = -2
        self.layer!.addSublayer(_bgLayer)
        
        _barsLayer = BarsLayer()
        _barsLayer.zPosition = -1
        self.layer!.addSublayer(_barsLayer)

        _mousePositionLayer = CALayer()
        _mousePositionLayer.backgroundColor = NSColor.gray.cgColor
        _mousePositionLayer.isHidden = true
        self.layer!.addSublayer(_mousePositionLayer)

        _positionLayer = CALayer()
        _positionLayer.backgroundColor = CGColor.white
        self.layer!.addSublayer(_positionLayer)
        
        let trackingArea = NSTrackingArea(rect: self.bounds,
                                          options: [.activeInActiveApp, .inVisibleRect, .assumeInside, .mouseEnteredAndExited, .mouseMoved],
                                          owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)

        self.timer = Timer.scheduledTimer(withTimeInterval: updateTime, repeats: true) { _ in
            // Only update the bars for x steps after transition
            if self.transitionSteps > 0 {
                let drawValues = self.analysis?.values ?? Array(repeating: Array(repeating: CGFloat(0), count: Analysis.sampleCount), count: 4)
                self._barsLayer.values = (0..<4).map { lerp(self._barsLayer.values[$0], drawValues[$0], self.lerpRatio) }
            }
            
            if self.analysis?.complete ?? true { self.transitionSteps -= 1}

            CATransaction.begin()
            CATransaction.setAnimationDuration(self.updateTime)
            if let location = self.location {
                self._positionLayer.frame.origin.x = CGFloat(location) * self.bounds.width
                self._positionLayer.isHidden = false
            }
            else {
                self._positionLayer.isHidden = true
            }
            CATransaction.commit()
        }
    }
    
    func reset() {
        CATransaction.begin()
        CATransaction.setValue(true, forKey:kCATransactionDisableActions)
        self._positionLayer.isHidden = true
        CATransaction.commit()

        location = nil
        self._barsLayer.values = BarsLayer.defaultValues
    }
    
    func layoutSublayers(of layer: CALayer) {
        _barsLayer.frame = layer.bounds
        _bgLayer.frame = layer.bounds
        _positionLayer.frame = CGRect(
            x: _positionLayer.frame.origin.x,
            y: _positionLayer.frame.origin.y,
            width: 1,
            height: layer.bounds.height
        )
        _mousePositionLayer.frame = _positionLayer.frame
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
    
    override func mouseEntered(with event: NSEvent) {
        _mousePositionLayer.isHidden = false
    }
    
    override func mouseExited(with event: NSEvent) {
        _mousePositionLayer.isHidden = true
    }
    
    override func mouseMoved(with event: NSEvent) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey:kCATransactionDisableActions)
        _mousePositionLayer.frame.origin.x = self.convert(event.locationInWindow, from:nil).x
        CATransaction.commit()
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
