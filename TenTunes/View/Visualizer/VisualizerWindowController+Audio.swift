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
    @objc class AudioConnection : NSObject {
        let fft: FFTTap.AVNode
        let pause: (() -> VisualizerWindow.PauseResult)?
        
        init(fft: FFTTap.AVNode, pause: (() -> VisualizerWindow.PauseResult)? = nil) {
            self.fft = fft
            self.pause = pause
        }
    }
    
    enum AudioCapture {
        case direct
        case input(device: AKDevice)
//        case output(device: AKDevice)
    }
    
    @IBAction func selectedAudioSource(_ sender: Any) {
        updateFFT()
    }

    func updateAudioSources() {
        _audioSourceSelector.removeAllItems()
        
        _audioSourceSelector.addItem(withTitle: "Ten Tunes")
        _audioSourceSelector.lastItem!.representedObject = AudioCapture.direct
        
        _audioSourceSelector.menu!.addItem(NSMenuItem.separator())
        
        for device in AudioKit.inputDevices ?? [] {
            _audioSourceSelector.addItem(withTitle: device.name)
            _audioSourceSelector.lastItem!.representedObject = AudioCapture.input(device: device)
        }

//        _audioSourceSelector.menu!.addItem(NSMenuItem.separator())
//
//        for device in AudioKit.outputDevices ?? [] {
//            _audioSourceSelector.addItem(withTitle: device.name)
//            _audioSourceSelector.lastItem!.representedObject = AudioCapture.output(device: device)
//        }
    }
    
    func updateFFT() {
        guard let captureMethod = _audioSourceSelector.selectedItem?.representedObject as? AudioCapture else {
            return // Eh?
        }
        
        let visible = window?.occlusionState.contains(.visible) ?? false
        
        connection?.fft.stop()
        connection = nil

        guard visible || syphon != nil else {
            return
        }
        
        do {
            switch captureMethod {
            case .direct:
                let player = ViewController.shared.player
                connection = .init(fft: try! FFTTap.AVNode(player.mixer.avAudioNode),
                    pause: {
                        player.togglePlay()
                        return player.isPlaying ? .played : .paused
                    }
                )
            case .input(let device):
                connection = .init(fft: try FFTTap.AVAudioDevice(deviceID: device.deviceID))
//        case .output(let device):
//            break
            }
        }
        catch {
            NSAlert(error: error).runModal()
        }
        
        connection?.fft.volume = volume
        connection?.fft.addObserver(self, forKeyPath: #keyPath(FFTTap.AVNode.resonance), options: [.new], context: nil)
    }
}
