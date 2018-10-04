//
//  VisualizerWindowController+Audio.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AudioKitUI

extension VisualizerWindowController {
    @IBAction func selectedAudioSource(_ sender: Any) {
        updateFFT()
    }

    func updateAudioSources() {
        _audioSourceSelector.removeAllItems()
        
        _audioSourceSelector.addItem(withTitle: "Ten Tunes")
        
        for input in AudioKit.inputDevices ?? [] {
            _audioSourceSelector.addItem(withTitle: input.name)
            _audioSourceSelector.lastItem!.representedObject = input
        }
    }
    
    func updateFFT() {
        let inputDevice = _audioSourceSelector.selectedItem?.representedObject as? AKDevice
        
        let visible = window?.occlusionState.contains(.visible) ?? false
        
        guard visible || syphon != nil else {
            fft = nil
            return
        }
        
        guard let device = inputDevice else {
            fft = nil // Deinit first, if we had one before it has to remove the bus tap
            fft = FFTTap.AudioKitNode(node: ViewController.shared.player.mixer)
            return
        }
        
        fft = FFTTap.AVAudioDevice(deviceID: device.deviceID)
    }
}
