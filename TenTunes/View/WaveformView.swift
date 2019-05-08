//
//  WaveformView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import Defaults

class BarsLayer: CALayer {
    static var defaultValues: Analysis.Values {
        return .placeholder(lows: 0.0, mids: 1.0, highs: 0.0, count: Analysis.sampleCount)
    }
    
    static var failedValues: Analysis.Values {
        return .placeholder(lows: 1.0, mids: 0.0, highs: 0.0, count: Analysis.sampleCount)
    }
    
    static var currentBarColorLUT: [CGColor] {
        return Array(1 ..< 100).map {
            let rotation = CGFloat(AppDelegate.defaults[.waveformColorRotation])
            
            // Don't go the full way so we don't loop back to the start
            return NSColor(
                hue: (1 + rotation + CGFloat($0) / 100 * 0.8).truncatingRemainder(dividingBy: 1),
                saturation: CGFloat(0.33),
                brightness: CGFloat(0.8),
                alpha: CGFloat(1.0)
            ).cgColor
        }
    }
    
    static var barColorLUT: [CGColor] = BarsLayer.currentBarColorLUT
    
    static func barColor(_ value: CGFloat) -> CGColor {
        return barColorLUT[(0 ... barColorLUT.count - 1)
            .clamp(Int(value * CGFloat(barColorLUT.count)))]
    }
    
    static func values(from analysis: Analysis?) -> Analysis.Values {
        guard let analysis = analysis else {
            return defaultValues
        }
        
        return analysis.values ?? failedValues
    }
    
    var values: Analysis.Values = BarsLayer.defaultValues {
        didSet {
            layoutSublayers()
        }
    }
    
    var barWidth = 2
    var spaceWidth = 2
    
    var defaultsObservers: [DefaultsObservation] = []
    
    override init() {
        super.init()
        startObservers()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        startObservers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        startObservers()
    }
    
    func startObservers() {
        let display = { [unowned self] (_ : Any) in
            self.setNeedsLayout()
        }
        
        defaultsObservers = [
            UserDefaults.swifty.observe(.waveformDisplay, options: [.new]) { display($0) },
            UserDefaults.swifty.observe(.waveformColorRotation, options: [.new]) {
                // Will be called for each view, but eh
                BarsLayer.barColorLUT = BarsLayer.currentBarColorLUT
                display($0)
            },
        ]
    }
    
    private func ensureSublayerCount<T: CALayer>(_ count: Int, of kind: T.Type) {
        let diffLayers = count - (sublayers?.count ?? 0)
        if diffLayers > 0 {
            sublayers = (sublayers ?? []) + (0 ..< diffLayers).map { _ in
                kind.init()
            }
        }
        else if diffLayers < 0 {
            sublayers?.removeLast(diffLayers)
        }
    }
    
    override func layoutSublayers() {
        let barWidth = CGFloat(self.barWidth)
        let spaceWidth = CGFloat(self.spaceWidth)
        
        let segmentWidth = barWidth + spaceWidth
        
        let numBars = Int(frame.width / segmentWidth)
        ensureSublayerCount(numBars, of: CAShapeLayer.self)
        
        guard let bars = sublayers as! [CAShapeLayer]? else {
            // Nothing to draw
            return
        }
        
        let values = self.values.remapped(toSize: numBars)
        
        let start = frame.minX + (frame.width - CGFloat(numBars) * segmentWidth) / 2
        
        let display = AppDelegate.defaults[.waveformDisplay]
        
        for (idx, layer) in bars.enumerated() {
            // Frame
            let h = values.waveform[idx]
            
            // Color
            let low = values.lows[idx] * values.lows[idx]
            let mid = values.mids[idx] * values.mids[idx]
            let high = values.highs[idx] * values.highs[idx]
            
            let val = low + mid + high
            let color = val > 0 ? BarsLayer.barColor((mid / val / 2 + high / val)) : nil

            let barX = start + CGFloat(idx) * segmentWidth + 1
            let barHeight = CGFloat(h * frame.height)
            
            if display == .bars {
                color.map { layer.backgroundColor = $0 }
                
                layer.frame = CGRect(
                    x: barX,
                    y: frame.minY,
                    width: barWidth,
                    height: barHeight
                )
            }
            else if display == .rounded {
                layer.backgroundColor = nil
                color.map { layer.fillColor = $0 }
                
                let next = CGFloat((values.waveform[safe: idx + 1] ?? h) * frame.height)
                
                let path = CGMutablePath()
                // TODO
                path.move(to: CGPoint(x: barX, y: frame.minY))
                path.addLine(to: CGPoint(x: barX + barWidth + spaceWidth, y: frame.minY))
                path.addLine(to: CGPoint(x: barX + barWidth + spaceWidth, y: frame.minY + next))
                path.addLine(to: CGPoint(x: barX, y: frame.minY + barHeight))
                
                layer.path = path.copy()
            }
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
            updateLocation(of: _positionLayer, to: location)
        }
    }
    var mouseLocation: Double? {
        didSet {
            updateLocation(of: _mousePositionLayer, to: mouseLocation)
        }
    }
    
    override init() {
        super.init()
        
        actions = [
            "onOrderOut": NSNull(),
            "onOrderIn": NSNull(),
            "sublayers": NSNull(),
            "contents": NSNull(),
            "bounds": NSNull(),
        ] // Disable fade outs
        
        _barsLayer.actions = actions
        _bgLayer.actions = actions

        let gradientSteps = 10
        _bgLayer.colors = (0 ... gradientSteps).reversed().map {
            NSColor.black.withAlphaComponent(CGFloat($0) * 0.5 / CGFloat(gradientSteps)).cgColor
        }
        // "Ease In"
        _bgLayer.locations = (0 ... gradientSteps).map { NSNumber(value: pow(Double($0) / Double(gradientSteps), 2)) }
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
            width: max(1, min(3, 8 - bounds.size.height / 3)),
            height: bounds.height
        )
        _mousePositionLayer.frame = _positionLayer.frame
        
        updateLocation(of: _positionLayer, to: location)
        updateLocation(of: _mousePositionLayer, to: mouseLocation)
    }
    
    func updateLocation(of layer: CALayer, to: Double?) {
        if let location = to {
            layer.frame.origin.x = CGFloat(location) * self.bounds.width - layer.frame.size.width / 2
            layer.isHidden = false
        }
        else {
            layer.isHidden = true
        }
    }
}

class WaveformView: NSControl, CALayerDelegate {
    var location: Double? {
        set { locationRatio = newValue.map { $0 / (track?.duration?.seconds ?? 1) } }
        get { return locationRatio.map { $0 * (track?.duration?.seconds ?? 1) } }
    }
    
    var locationRatio: Double? {
        set {
            waveformLayer.location = newValue
            waveformLayer.mouseLocation = waveformLayer.mouseLocation != nil ? (window?.mouseLocationOutsideOfEventStream ?=> relativeX) ?=> jumpPosition : nil
        }
        get { return waveformLayer.location }
    }
    var track: Track?
    
    var analysis: Analysis? {
        set(analysis) {
            guard _analysis !== analysis else {
                return
            }
            
            transitionToAnalysis(analysis)
        }
        get { return _analysis }
    }
    var _analysis: Analysis? = nil
    
    var waveformLayer : WaveformLayer {
        return layer as! WaveformLayer
    }
    
    var timer: Timer? = nil
    
    @IBInspectable
    var updateTime : Double = 1.0 / 30.0 {
        didSet {
            guard updateTime != oldValue else {
                return
            }
            
            // To possibly update timer
            transitionToAnalysis(analysis)
        }
    }

    var barWidth: Int {
        set(barWidth) { waveformLayer._barsLayer.barWidth = barWidth }
        get { return waveformLayer._barsLayer.barWidth }
    }
    var spaceWidth: Int {
        set(spaceWidth) { waveformLayer._barsLayer.spaceWidth = spaceWidth }
        get { return waveformLayer._barsLayer.spaceWidth }
    }
    
    var jumpSegment: Double = 0
    
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
        
        let trackingArea = NSTrackingArea(rect: self.bounds,
                                          options: [.activeInActiveApp, .inVisibleRect, .assumeInside, .mouseEnteredAndExited, .mouseMoved],
                                          owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    private func transitionToAnalysis(_ analysis: Analysis?) {
        _analysis = analysis
        
        guard !(analysis?.complete ?? true) else {
            // Transition slowly

            timer?.invalidate()
            timer = nil
            
            transitionToCompleteAnalysis()

            return
        }

        // Transition while analysing
        
        guard timer?.timeInterval != updateTime else {
            // Just keep the current animation timer
            
            return
        }
        
        timer?.invalidate()
        
        if visibleRect == NSZeroRect || superview == nil {
            // Invisible yet, better start fresh
            waveformLayer._barsLayer.values = BarsLayer.defaultValues
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: updateTime, repeats: true) { timer in
            guard let analysis = self.analysis, !analysis.complete else {
                // Done
                timer.invalidate()
                self.timer = nil
                
                self.transitionToCompleteAnalysis()
                
                return
            }
            
            guard let drawValues = analysis.values else {
                // Wait until it has a values object
                return
            }
            
            // Only update the bars for x steps after transition
            CATransaction.begin()
            CATransaction.setAnimationDuration(self.updateTime)
            
            self.waveformLayer._barsLayer.values = self.waveformLayer._barsLayer.values.interpolateLinear(to: drawValues, by: CGFloat(6 * self.updateTime))

            CATransaction.commit()
        }
        timer?.tolerance = .seconds(timer!.timeInterval / 4)
    }
    
    private func transitionToCompleteAnalysis() {
        var drawValues: Analysis.Values?
        
        if let analysis = self.analysis {
            drawValues = analysis.values ?? BarsLayer.failedValues
        }
        else {
            drawValues = BarsLayer.defaultValues
        }
        
        guard AppDelegate.defaults[.animateWaveformTransitions], visibleRect != NSZeroRect, superview != nil else {
            // Transition Instantly
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            waveformLayer._barsLayer.values = drawValues!
            
            CATransaction.commit()

            return
        }
        
        // Transition Smoothly
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(.seconds(0.2))
        CATransaction.setAnimationTimingFunction(.init(name: .easeInEaseOut))

        waveformLayer._barsLayer.values = drawValues!
        
        CATransaction.commit()
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    func click(at: Double) {
        guard analysis != nil else {
            return
        }

        self.locationRatio = (0.0...1.0).clamp(jumpPosition(for: at))
        
        if let action = self.action, let target = self.target {
            NSApp.sendAction(action, to: target, from: self)
        }
    }
    
    func relativeX(_ point: NSPoint) -> Double {
        return Double(self.convert(point, from:nil).x / bounds.size.width)
    }
    
    func jumpPosition(for position: Double) -> Double {
        guard NSEvent.modifierFlags.contains(.option) != AppDelegate.defaults[.quantizedJump] else {
            return position
        }
        
        guard jumpSegment > 0, jumpSegment < 1, let locationRatio = self.locationRatio else {
            return position
        }
        
        return locationRatio + ((position - locationRatio) / jumpSegment).rounded() * jumpSegment
    }
    
// If anything, play at increased or decreased speeds. But just setting position sounds crap
// TODO Re-enable this but during drag, pause current track
//    override func mouseDragged(with event: NSEvent) {
//        self.click(at: relativeX(event.locationInWindow))
//    }
    
    override func mouseDown(with event: NSEvent) {
        self.click(at: relativeX(event.locationInWindow))
    }
    
    override func mouseEntered(with event: NSEvent) {
        guard analysis != nil else {
            return
        }
        
        waveformLayer.mouseLocation = jumpPosition(for: relativeX(event.locationInWindow))
    }
    
    override func mouseExited(with event: NSEvent) {
        waveformLayer.mouseLocation = nil
    }
    
    override func mouseMoved(with event: NSEvent) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey:kCATransactionDisableActions)
        waveformLayer.mouseLocation = jumpPosition(for: relativeX(event.locationInWindow))
        CATransaction.commit()
    }
}

import AVFoundation

extension WaveformView {
    func updateLocation(_ location: Double?, duration: CMTime) {
        guard location != self.location else {
            return
        }
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration.seconds)
        
        self.location = location

        CATransaction.commit()
    }
    
    func observe(for track: Track?, in player: Player) {
        self.track = track
        
        NotificationCenter.default.removeObserver(self, name: ViewController.userInterfaceUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(forName: ViewController.userInterfaceUpdateNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            guard let `self` = self else {
                return // Deallocated in the meantime
            }
            
            let matchesTrack = self.track != nil ? self.track == player.playing : player.playing != nil
            self.updateLocation(matchesTrack ? player.currentTime : nil,
                           duration: ViewController.userInterfaceUpdateDuration)
        }
    }
}
