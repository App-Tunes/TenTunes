//
//  CoreAudio+TT.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.10.20.
//  Copyright © 2020 ivorius. All rights reserved.
//

import Foundation
import AudioKit

class CoreAudioTT {
    struct OSError: Error {
        var code: OSStatus
    }
    
    static func device(ofUnit unit: AudioUnit) -> UInt32? {
        var deviceID: DeviceID = 0
        var propertySize: UInt32 = UInt32(MemoryLayout.size(ofValue: deviceID))
        
        let error = AudioUnitGetProperty(unit,
                             kAudioOutputUnitProperty_CurrentDevice,
                             kAudioUnitScope_Global, 0,
                             &deviceID,
                             &propertySize)
        
        if error != 0 {
            print("Could not get current device: \(error)")
            return nil
        }
        
        return deviceID
    }
    
    static func volume(ofDevice device: UInt32, channel: UInt32? = nil) -> Float? {
        do {
            let channels = channel.map { $0...$0 } ?? 1...2
            let volumes = try channels.map { try getObjectProperty(
                object: device,
                selector: kAudioDevicePropertyVolumeScalar,
                scope: kAudioDevicePropertyScopeOutput,
                example: Float32(),
                channel: $0
            )}
            return volumes.max()
        }
        catch let error {
            print("Could not get volume: \(error)")
        }
        
        return nil
    }
        
    static func setVolume(ofDevice device: UInt32, _ volume: Float) {
        do {
            let channels: ClosedRange<UInt32> = 1...2
            let volumes = channels.map { Self.volume(ofDevice: device, channel: $0) ?? 0 }
            let max = volumes.max() ?? 1
            let ratios = volumes.map { max > 0 ? $0 / max : 1 }
            
            for (ratio, channel) in zip(ratios, channels) {
                try setObjectProperty(
                    object: device,
                    selector: kAudioDevicePropertyVolumeScalar,
                    scope: kAudioDevicePropertyScopeOutput,
                    value: volume * ratio,
                    channel: channel
                )
            }
        }
        catch let error {
            print("Could not set volume: \(error)")
        }
    }
        
    static var defaultOutputDevice: UInt32? {
        do {
            return try getObjectProperty(
                object: AudioObjectID(kAudioObjectSystemObject),
                selector: kAudioHardwarePropertyDefaultSystemOutputDevice,
                scope: kAudioObjectPropertyScopeGlobal,
                example: AudioDeviceID()
            )
        }
        catch let error {
            print("Could not get default device: \(error)")
        }
        
        return nil
    }
    
    static func getObjectProperty<T>(object: AudioObjectID, selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope, example: T, channel: UInt32 = 0) throws -> T {
        var propertySize = UInt32(MemoryLayout<T>.size)
        var property = example // TODO Instead pass type lol
        var propertyAddress = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: channel)

        let error = AudioObjectGetPropertyData(object, &propertyAddress, 0, nil, &propertySize, &property)

        guard error == 0 else {
            throw OSError(code: error)
        }
        
        return property
    }
    
    static func setObjectProperty<T>(object: AudioObjectID, selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope, value: T, channel: UInt32 = 0) throws {
        var property = value
        var propertyAddress = AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: channel)
        let propertySize = UInt32(MemoryLayout<T>.size)

        let error = AudioObjectSetPropertyData(object, &propertyAddress, 0, nil, propertySize, &property)

        if error != 0 {
            throw OSError(code: error)
        }
    }
}
