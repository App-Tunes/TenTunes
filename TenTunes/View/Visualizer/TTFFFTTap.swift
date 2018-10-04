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

@objc protocol TTFFFTTap {
    var fftData: [Double] { get }
    @objc var volume: Double { get set }
    
    func stop()
}

class FFTTap {
    class AudioKitNode: NSObject, TTFFFTTap {
        let node: AKMixer
        let tap: AKFFTTap
        
        var volume: Double = 1
        
        init(node: AKMixer) {
            self.node = node
            tap = AKFFTTap(node)
        }
        
        var fftData: [Double] { return tap.fftData.map { $0 * volume } }
        
        func stop() {
            node.avAudioNode.removeTap(onBus: 0)
        }
        
        deinit { stop() }
    }
    
    class AVAudioDevice: NSObject, TTFFFTTap, EZAudioFFTDelegate {
        let bufferSize: UInt32 = 1_024
        open var fftData = [Double](zeros: 512)
        internal var fft: EZAudioFFT?
        
        let engine = AVAudioEngine()
        
        var volume: Double = 1
        
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
                self.fftData[i] = Double(fftData[i]) * volume
            }
        }
        
        func stop() {
            if engine.isRunning {
                engine.stop()
            }
        }
        
        deinit { stop() }
    }
}

