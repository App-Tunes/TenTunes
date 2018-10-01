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
    
    var useMicrophone = false
    
    var fft: AKFFTTap?
    var microphoneNode: AKMicrophone?

    var trackingTag: NSView.TrackingRectTag?
    
    @IBOutlet var _settingsButton: NSButton!
    @IBOutlet var _settingsSheet: NSPanel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        window!.ignoresMouseEvents = false
        updateTrackingAreas(true)
        hideWindowButtons()
        
        _settingsButton.alphaValue = 0.35
    }
    
    func hideWindowButtons() {
        window!.standardWindowButton(.closeButton)!.alphaValue = 0.01
        window!.standardWindowButton(.zoomButton)!.alphaValue = 0.01
        window!.standardWindowButton(.miniaturizeButton)!.alphaValue = 0.01
        _settingsButton.isHidden = true
    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        if trackingTag == theEvent.trackingNumber {
            window!.standardWindowButton(.closeButton)!.alphaValue = 0.35
            window!.standardWindowButton(.zoomButton)!.alphaValue = 0.35
            window!.standardWindowButton(.miniaturizeButton)!.alphaValue = 0.35
            _settingsButton.isHidden = false
        }
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        if trackingTag == theEvent.trackingNumber {
            hideWindowButtons()
        }
    }
    
    func updateTrackingAreas(_ establish : Bool) {
        trackingTag ?=> window!.standardWindowButton(.closeButton)!.removeTrackingRect

        if establish {
            trackingTag = window!.contentView!.addTrackingRect(window!.contentView!.bounds, owner: self, userData: nil, assumeInside: false)
        }
    }
    
    @IBAction func showSettings(_ sender: Any) {
        window?.beginSheet(_settingsSheet)
    }
}

extension VisualizerWindowController : NSWindowDelegate {
    func windowDidChangeOcclusionState(_ notification: Notification) {
        let visible = window?.occlusionState.contains(.visible) ?? false
        if visible && fft == nil {
            guard !useMicrophone else {
                let microphoneNode = AKMicrophone()
                microphoneNode.start()
                microphoneNode.volume = 3
                print(microphoneNode.isStarted)
                
                fft = AKFFTTap(microphoneNode)
                self.microphoneNode = microphoneNode
                
                return
            }

            fft = AKFFTTap(ViewController.shared.player.mixer)
        }
        else if !visible && fft != nil {
            fft = nil

            guard !useMicrophone else {
                microphoneNode = nil
                
                return
            }
            
            // According to AKFFTTap class reference, it will always be on tap 0
            ViewController.shared.player.mixer.avAudioNode.removeTap(onBus: 0)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        window!.ignoresMouseEvents = true
        updateTrackingAreas(false)
        return true
    }
}

extension VisualizerWindowController : VisualizerViewDelegate {
    func visualizerViewFFTData(_ view: VisualizerView) -> [Double]? {
        if window!.isKeyWindow, window!.isMouseInside, GLSLView.timeMouseIdle() > 2 {
            NSCursor.setHiddenUntilMouseMoves(true)
        }
        
        return fft?.fftData
    }
}
