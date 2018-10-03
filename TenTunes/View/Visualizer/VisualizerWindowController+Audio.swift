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
        inputDevice = (sender as! NSPopUpButton).selectedItem?.representedObject as? AKDevice
    }

    func updateAudioSources() {
        _audioSourceSelector.removeAllItems()
        
        _audioSourceSelector.addItem(withTitle: "Ten Tunes")
        
        for input in AudioKit.inputDevices ?? [] {
            _audioSourceSelector.addItem(withTitle: input.name)
            _audioSourceSelector.lastItem!.representedObject = input
        }
    }
    
    func updateAudioNode() {
        let visible = window?.occlusionState.contains(.visible) ?? false
        
        if !visible && syphon == nil {
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
