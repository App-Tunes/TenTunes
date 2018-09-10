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
}

extension VisualizerWindowController : VisualizerViewDelegate {
    func visualizerViewFFTData(_ view: VisualizerView) -> [Double]? {
        return fft?.fftData
    }
}
