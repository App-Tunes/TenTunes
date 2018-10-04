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

@objc protocol ResonanceProvider {
    @objc var resonance: [Double] { get }
    @objc var volume: Double { get set }
    
    func stop()
}

class FFTTap {
    class AVNode: NSObject, ResonanceProvider, EZAudioFFTDelegate {
        let bufferSize: UInt32 = 1_024

        let node: AVAudioNode
        var fft: EZAudioFFT? = nil
        
        @objc dynamic var volume: Double = 1
        @objc dynamic var resonance = [Double](zeros: 512)

        init(_ node: AVAudioNode) {
            self.node = node
            
            super.init()
            
            fft = EZAudioFFT(maximumBufferSize: vDSP_Length(bufferSize),
                             sampleRate: Float(AKSettings.sampleRate),
                             delegate: self)
            node.installTap(onBus: 0,
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
            resonance = Array(0 ..< 512).map { Double(fftData![$0]) * volume }
        }
        
        func stop() {
            node.removeTap(onBus: 0)
        }
        
        deinit { stop() }
    }
    
    class AVAudioDevice: AVNode  {
        let engine: AVAudioEngine
        
        init(deviceID: AudioDeviceID) throws {
            engine = AVAudioEngine()
            
            let input = engine.inputNode
            var changingDeviceID = deviceID
            
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultInputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMaster)
            try AudioObjectSetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &address, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &changingDeviceID).explode()
            
            let player = AVAudioPlayerNode()
            engine.attach(player)
            
            let inputFormat = input.inputFormat(forBus: 0)
            engine.connect(player, to: engine.mainMixerNode, format: inputFormat)
            
            try engine.start()

            super.init(input)
        }
        
        override func stop() {
            super.stop()
            
            if engine.isRunning {
                engine.stop()
            }
        }
    }
}

