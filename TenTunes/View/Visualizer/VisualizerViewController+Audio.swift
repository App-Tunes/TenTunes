//
//  VisualizerViewController+Audio.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import AudioKit

extension Visualizer {
    enum AudioCapture {
        case direct
        case input(device: AKDevice)
        //        case output(device: AKDevice)
    }
}

extension VisualizerViewController {
    @objc class AudioConnection : NSObject {
        let fft: FFTTap.AVNode
        let pause: (() -> Visualizer.PauseResult)?
        
        init(fft: FFTTap.AVNode, pause: (() -> Visualizer.PauseResult)? = nil) {
            self.fft = fft
            self.pause = pause
        }
    }
    
    @IBAction func selectedAudioSource(_ sender: Any) {
        guard let source = _audioSourceSelector.lastItem?.representedObject as? Visualizer.AudioCapture else {
            return // Eh?
        }
        
        audioSource = source
    }
    
    func updateAudioSources() {
        _audioSourceSelector.removeAllItems()
        
        _audioSourceSelector.addItem(withTitle: "Ten Tunes")
        _audioSourceSelector.lastItem!.representedObject = Visualizer.AudioCapture.direct
        
        _audioSourceSelector.menu!.addItem(NSMenuItem.separator())
        
        for device in AKManager.inputDevices ?? [] {
            _audioSourceSelector.addItem(withTitle: device.name)
            _audioSourceSelector.lastItem!.representedObject = Visualizer.AudioCapture.input(device: device)
        }
        
        //        _audioSourceSelector.menu!.addItem(NSMenuItem.separator())
        //
        //        for device in AKManager.outputDevices ?? [] {
        //            _audioSourceSelector.addItem(withTitle: device.name)
        //            _audioSourceSelector.lastItem!.representedObject = AudioCapture.output(device: device)
        //        }
    }

    func updateFFT() {
        let visible = view.visibleRect != NSZeroRect
        
        connection?.fft.stop()
        connection = nil
        
        guard visible || syphon != nil else {
            return
        }
        
        do {
            switch audioSource {
            case .direct:
                let player = ViewController.shared.player
				guard let node = player.playingEmitter?.engine.mainMixerNode else {
					// Can't establish connection
					return
				}
				
				connection = .init(
					fft: try! FFTTap.AVNode(node),
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
