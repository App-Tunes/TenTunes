//
//  TTFFFTTap.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation
import AudioKitUI

protocol TTFFFTTap {
    var fftData: [Double] { get }
}

class FFTTap {
    class AudioKitNode: TTFFFTTap {
        let node: AKNode
        let tap: AKFFTTap
        
        init(node: AKNode) {
            self.node = node
            tap = AKFFTTap(node)
        }
        
        var fftData: [Double] { return tap.fftData }
        
        deinit {
            node.avAudioNode.removeTap(onBus: 0)
        }
    }
    
    class AVAudioDevice: NSObject, TTFFFTTap, EZAudioFFTDelegate {
        let bufferSize: UInt32 = 1_024
        open var fftData = [Double](zeros: 512)
        internal var fft: EZAudioFFT?
        
        let engine = AVAudioEngine()
        
        init(deviceID: AudioDeviceID) {
            super.init()
            
            let input = engine.inputNode
            var changingDeviceID = deviceID
            
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultInputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMaster)
            AudioObjectSetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &address, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &changingDeviceID)
            
            let player = AVAudioPlayerNode()
            engine.attach(player)
            
            let bus = 0
            let inputFormat = input.inputFormat(forBus: bus)
            engine.connect(player, to: engine.mainMixerNode, format: inputFormat)
            
            try! engine.start()
            
            fft = EZAudioFFT(maximumBufferSize: vDSP_Length(bufferSize),
                             sampleRate: Float(AKSettings.sampleRate),
                             delegate: self)
            input.installTap(onBus: 0,
                             bufferSize: bufferSize,
                             format: AudioKit.format) { [weak self] (buffer, _) -> Void in
                                guard let strongSelf = self else {
                                    AKLog("Unable to create strong reference to self")
                                    return
                                }
                                buffer.frameLength = strongSelf.bufferSize
                                let offset = Int(buffer.frameCapacity - buffer.frameLength)
                                if let tail = buffer.floatChannelData?[0], let existingFFT = strongSelf.fft {
                                    existingFFT.computeFFT(withBuffer: &tail[offset],
                                                           withBufferSize: strongSelf.bufferSize)
                                }
            }
        }
        
        func fft(_ fft: EZAudioFFT!, updatedWithFFTData fftData: UnsafeMutablePointer<Float>!, bufferSize: vDSP_Length) {
            for i in 0..<512 {
                self.fftData[i] = Double(fftData[i])
            }
        }
        
        deinit {
            engine.stop()
        }
    }
}

