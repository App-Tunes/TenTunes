//
//  VisualizerWindowController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AudioKitUI

class VisualizerWindowController: NSWindowController {

    @IBOutlet var _visualizerView: VisualizerView!
    
    @objc dynamic var fft: FFTTap.AVNode?

    var silence: AKNode?
    var tracker: AKFrequencyTracker?

    var syphon: LiveSyphonServer?

    var trackingArea : NSTrackingArea?

    @IBOutlet var _settingsButton: NSButton!
    @IBOutlet var _settingsSheet: NSPanel!
    @IBOutlet var _audioSourceSelector: NSPopUpButton!
    @IBOutlet var _renderingMethodSelector: NSPopUpButton!
    
    @IBOutlet var _windowWidth: EnterReturningTextField!
    @IBOutlet var _windowHeight: EnterReturningTextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateTrackingAreas()
        updateWindowButtons(show: false)

        _settingsButton.alphaValue = 0.35
        
        AudioKit.addObserver(self, forKeyPath: #keyPath(AudioKit.inputDevices), options: [.new, .initial], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AudioKit.inputDevices) {
            updateAudioSources()
        }
        else if keyPath == #keyPath(ResonanceProvider.resonance) {
            _visualizerView.update(withFFT: (object as! ResonanceProvider).resonance)
        }
    }
    
    func updateWindowButtons(show: Bool) {
        let alpha: CGFloat = show ? 0.35 : 0.01
        window!.standardWindowButton(.closeButton)!.alphaValue = alpha
        window!.standardWindowButton(.zoomButton)!.alphaValue = alpha
        window!.standardWindowButton(.miniaturizeButton)!.alphaValue = alpha
        _settingsButton.isHidden = !show
    }
    
    override func mouseMoved(with event: NSEvent) {
        updateWindowButtons(show: true)
    }
    
    override func mouseExited(with event: NSEvent) {
        updateWindowButtons(show: false)
    }
    
    func updateTrackingAreas() {
        let view = window!.contentView!
        
        trackingArea ?=> view.removeTrackingArea

        trackingArea = NSTrackingArea(rect: view.bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil)
        view.addTrackingArea(trackingArea!)
    }
    
    @IBAction func showSettings(_ sender: Any) {
        window?.beginSheet(_settingsSheet)
    }
    
    @IBAction func updateWindowSize(_ sender: Any) {
        guard let width = Int(_windowWidth.stringValue), let height = Int(_windowHeight.stringValue) else {
            return
        }
        window?.setContentSize(NSSize(width: width, height: height))
    }
}

extension VisualizerWindowController : NSWindowDelegate {
    func windowDidChangeOcclusionState(_ notification: Notification) {
        updateFFT()
    }
    
    func windowDidResize(_ notification: Notification) {
        updateTrackingAreas()
        
        _windowWidth.stringValue = String(Int(window!.contentView!.frame.size.width))
        _windowHeight.stringValue = String(Int(window!.contentView!.frame.size.height))
    }
}

extension VisualizerWindowController : VisualizerViewDelegate {
    func visualizerViewUpdate(_ view: VisualizerView) {
        if window!.isKeyWindow, window!.isMouseInside, RFOpenGLView.timeMouseIdle() > 2 {
            NSCursor.setHiddenUntilMouseMoves(true)
            DispatchQueue.main.async { self.updateWindowButtons(show: false) }
        }

        // Update on fft changes
//        view.update(withFFT: fft?.resonance)
    }
}
