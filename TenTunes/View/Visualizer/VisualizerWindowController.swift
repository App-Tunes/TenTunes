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
    var inputDevice: AKDevice? {
        didSet {
            inputNode = nil
            updateAudioNode()
        }
    }
    var inputNode: AKNode? {
        didSet {
            if fft != nil {
                // According to AKFFTTap class reference, it will always be on tap 0
                oldValue?.avAudioNode.removeTap(onBus: 0)
            }
            
            fft = inputNode ?=> AKFFTTap.init
        }
    }
    var silence: AKNode?

    var trackingArea : NSTrackingArea?

    @IBOutlet var _settingsButton: NSButton!
    @IBOutlet var _settingsSheet: NSPanel!
    @IBOutlet var _audioSourceSelector: NSPopUpButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateTrackingAreas()
        updateWindowButtons(show: false)

        _settingsButton.alphaValue = 0.35
        
        AudioKit.addObserver(self, forKeyPath: #keyPath(AudioKit.inputDevices), options: [.new, .initial], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AudioKit.inputDevices) {
            _audioSourceSelector.removeAllItems()
            
            _audioSourceSelector.addItem(withTitle: "Ten Tunes")
            
            for input in AudioKit.inputDevices ?? [] {
                _audioSourceSelector.addItem(withTitle: input.name)
                _audioSourceSelector.itemArray.last!.representedObject = input
            }
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
    
    @IBAction func selectedAudioSource(_ sender: Any) {
        inputDevice = (sender as! NSPopUpButton).selectedItem?.representedObject as? AKDevice
    }
    
    func updateAudioNode() {
        let visible = window?.occlusionState.contains(.visible) ?? false

        if !visible {
            inputNode = nil
        }
        else if inputNode == nil {
            guard let device = inputDevice else {
                inputNode = ViewController.shared.player.mixer
                return
            }
            
            do {
                try AudioKit.setInputDevice(device)
            }
            catch {
                print("Error setting input device: \(error)")
                return
            }

            let microphoneNode = AKMicrophone()

            do {
                try microphoneNode.setDevice(device)
            }
            catch {
                print("Failed setting node input device: \(error)")
                return
            }

            microphoneNode.start()
            microphoneNode.volume = 3
            print("Switched Node: \(microphoneNode), started: \(microphoneNode.isStarted)")

            inputNode = microphoneNode
            try! AudioKit.start()
        }
    }
}

extension VisualizerWindowController : NSWindowDelegate {
    func windowDidChangeOcclusionState(_ notification: Notification) {
        updateAudioNode()
    }
    
    func windowDidResize(_ notification: Notification) {
        updateTrackingAreas()
    }
}

extension VisualizerWindowController : VisualizerViewDelegate {
    func visualizerViewFFTData(_ view: VisualizerView) -> [Double]? {
        if window!.isKeyWindow, window!.isMouseInside, GLSLView.timeMouseIdle() > 2 {
            NSCursor.setHiddenUntilMouseMoves(true)
            DispatchQueue.main.async { self.updateWindowButtons(show: false) }
        }

        return fft?.fftData
    }
}
