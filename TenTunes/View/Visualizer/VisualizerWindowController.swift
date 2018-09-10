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
    
    var fft: AKFFTTap?

    var trackingTag: NSView.TrackingRectTag?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        window!.ignoresMouseEvents = false
        updateTrackingAreas(true)
        hideWindowButtons()
    }
    
    func hideWindowButtons() {
        window!.standardWindowButton(.closeButton)!.alphaValue = 0.01
        window!.standardWindowButton(.zoomButton)!.alphaValue = 0.01
        window!.standardWindowButton(.miniaturizeButton)!.alphaValue = 0.01
    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        if trackingTag == theEvent.trackingNumber {
            window!.standardWindowButton(.closeButton)!.alphaValue = 0.25
            window!.standardWindowButton(.zoomButton)!.alphaValue = 0.25
            window!.standardWindowButton(.miniaturizeButton)!.alphaValue = 0.25
        }
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        if trackingTag == theEvent.trackingNumber {
            hideWindowButtons()
        }
    }
    
    func updateTrackingAreas(_ establish : Bool) {
        if let tag = trackingTag {
            window!.standardWindowButton(.closeButton)!.removeTrackingRect(tag)
        }
        if establish {
            trackingTag = window!.contentView!.addTrackingRect(window!.contentView!.bounds, owner: self, userData: nil, assumeInside: false)
        }
    }
}

extension VisualizerWindowController : NSWindowDelegate {
    func windowDidChangeOcclusionState(_ notification: Notification) {
        let visible = window?.occlusionState.contains(.visible) ?? false
        if visible && fft == nil {
            fft = AKFFTTap(ViewController.shared.player.mixer)
            
            //        microphoneNode = AKMicrophone()
            //        microphoneNode.start()
            //        microphoneNode.volume = 3
            //        print(microphoneNode.isStarted)
            //        fft = AKFFTTap(microphoneNode)
        }
        else if !visible && fft != nil {
            // According to AKFFTTap class reference, it will always be on tap 0
            ViewController.shared.player.mixer.avAudioNode.removeTap(onBus: 0)
            fft = nil
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
