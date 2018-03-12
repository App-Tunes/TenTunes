//
//  WaveformView.swift
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
        return Array(repeating: Array(repeating: 0.1, count: Analysis.sampleCount), count: 4)
    }
    
    static var barColorLookup: [CGColor] = Array(1..<100).map {
        // Don't go the full way so we don't loop back to red
        NSColor(hue: CGFloat($0) / 100 * 0.8, saturation: CGFloat(0.3), brightness: CGFloat(0.8), alpha: CGFloat(1.0)).cgColor
    }
    
    static func barColor(_ value: CGFloat) -> CGColor {
        return barColorLookup[(0...barColorLookup.count - 1).clamp(Int(value * CGFloat(barColorLookup.count)))]
    }
    
    var values: [[CGFloat]] = defaultValues {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var barWidth = 2
    var spaceWidth = 2
    
    override func draw(in ctx: CGContext) {
        let segmentWidth = barWidth + spaceWidth

        let numBars = Int(frame.width / CGFloat(segmentWidth))
        
        let values = self.values.map { wf in wf.remap(toSize: numBars) }
        let waveform = values[0], lows = values[1], mids = values[2], highs = values[3]

        let start = frame.minX + (frame.width - CGFloat(numBars * segmentWidth)) / 2

        for idx in 0..<numBars {
            // Frame
            let h = waveform[idx]
            
            // Color
            let low = lows[idx] * lows[idx], mid = mids[idx] * mids[idx], high = highs[idx] * highs[idx]
            let val = low + mid + high
            
            if val > 0, h > 0 {
                let rect = CGRect(
                    x: start + CGFloat(idx * segmentWidth) + 1,
                    y: frame.minY,
                    width: CGFloat(barWidth),
                    height: CGFloat(h * frame.height)
                )

                ctx.setFillColor(BarsLayer.barColor((mid / val / 2 + high / val)))
                ctx.fill(rect)
            }
            // Else bar doesn't exist
        }
    }
}

class WaveformLayer : CALayer {
    var _barsLayer = BarsLayer()
    var _positionLayer = CALayer()
    var _mousePositionLayer = CALayer()
    var _bgLayer = CAGradientLayer()
    
    var location: Double? {
        didSet {
            _updateLocation(layer: _positionLayer, to: location)
        }
    }
    var mouseLocation: Double? {
        didSet {
            _updateLocation(layer: _mousePositionLayer, to: mouseLocation)
        }
    }
    
    override init() {
        super.init()
        
        actions = ["onOrderOut": NSNull()] // Disable fade outs

        _bgLayer.colors = [
            NSColor.black.withAlphaComponent(0.4).cgColor,
            NSColor.clear.cgColor
        ]
        _bgLayer.zPosition = -2
        addSublayer(_bgLayer)
        
         // So it doesn't blur
        _barsLayer.shouldRasterize = true
        _barsLayer.contentsScale = 2
        _barsLayer.rasterizationScale = 2
        // Redraw when resized
        _barsLayer.needsDisplayOnBoundsChange = true
        _barsLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        _barsLayer.zPosition = -1
        _barsLayer.barWidth = 2
        _barsLayer.spaceWidth = 2
        addSublayer(_barsLayer)
        
        _mousePositionLayer.backgroundColor = NSColor.gray.cgColor
        _mousePositionLayer.isHidden = true
        addSublayer(_mousePositionLayer)
        
        _positionLayer.backgroundColor = CGColor.white
        _positionLayer.isHidden = true
        addSublayer(_positionLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    override func layoutSublayers() {
        _barsLayer.frame = bounds
        _bgLayer.frame = bounds
        _positionLayer.frame = CGRect(
            x: _positionLayer.frame.origin.x,
            y: _positionLayer.frame.origin.y,
            width: 1,
            height: bounds.height
        )
        _mousePositionLayer.frame = _positionLayer.frame
        
        _updateLocation(layer: _positionLayer, to: location)
        _updateLocation(layer: _mousePositionLayer, to: mouseLocation)
    }
    
    func _updateLocation(layer: CALayer, to: Double?) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(1 / 30) // Make this quick

        if let location = to {
            layer.frame.origin.x = CGFloat(location) * self.bounds.width
            layer.isHidden = false
        }
        else {
            layer.isHidden = true
        }
        
        CATransaction.commit()
    }
}

class WaveformView: NSControl, CALayerDelegate {
    var location: Double? {
        set(location) { waveformLayer.location = location }
        get { return waveformLayer.location }
    }
    
    var analysis: Analysis? = nil {
        didSet {
            if analysis !== oldValue {
                transitionSteps = self.completeTransitionSteps
            }
        }
    }
    
    var waveformLayer : WaveformLayer {
        return layer as! WaveformLayer
    }
    
    var timer: Timer? = nil
    
    var transitionSteps = 0
    
    var updateTime = 1.0 / 30.0 {
        didSet {
            if updateTime != oldValue {
                updateTimer()
            }
        }
    }
    var lerpRatio = CGFloat(1.0 / 5.0)
    var completeTransitionSteps = 120

    var barWidth: Int {
        set(barWidth) { waveformLayer._barsLayer.barWidth = barWidth }
        get { return waveformLayer._barsLayer.barWidth }
    }
    var spaceWidth: Int {
        set(spaceWidth) { waveformLayer._barsLayer.spaceWidth = spaceWidth }
        get { return waveformLayer._barsLayer.spaceWidth }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _setup()
    }
    
    func _setup() {
        wantsLayer = true
        layer = WaveformLayer()
        waveformLayer._barsLayer.barWidth = barWidth
        waveformLayer._barsLayer.spaceWidth = spaceWidth
        
        let trackingArea = NSTrackingArea(rect: self.bounds,
                                          options: [.activeInActiveApp, .inVisibleRect, .assumeInside, .mouseEnteredAndExited, .mouseMoved],
                                          owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
        
        updateTimer()
    }
    
    func setInstantly(analysis: Analysis?) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey:kCATransactionDisableActions)
        
        self.analysis = analysis
        waveformLayer._barsLayer.values = analysis?.values ?? BarsLayer.defaultValues
        transitionSteps = analysis?.complete ?? true ? 0 : completeTransitionSteps
        
        CATransaction.commit()
    }
    
    func updateTimer() {
        transitionSteps = self.completeTransitionSteps

        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: updateTime, repeats: true) { timer in
            guard self.visibleRect != NSZeroRect else {
                return // Not visible, why update?
            }
            
            // Only update the bars for x steps after transition
            if self.transitionSteps > 0 {
                CATransaction.begin()
                CATransaction.setAnimationDuration(self.updateTime)

                let drawValues = self.analysis?.values ?? BarsLayer.defaultValues
                self.waveformLayer._barsLayer.values = (0..<4).map { lerp(self.waveformLayer._barsLayer.values[$0], drawValues[$0], self.lerpRatio) }

                CATransaction.commit()
            }
            
            if self.analysis?.complete ?? true { self.transitionSteps -= 1}
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
    
    override func mouseExited(with event: NSEvent) {
        waveformLayer.mouseLocation = nil
    }
    
    override func mouseMoved(with event: NSEvent) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey:kCATransactionDisableActions)
        waveformLayer.mouseLocation = Double(self.convert(event.locationInWindow, from:nil).x / bounds.size.width)
        CATransaction.commit()
    }
}

import AudioKit
import AudioKitUI

extension WaveformView {
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
