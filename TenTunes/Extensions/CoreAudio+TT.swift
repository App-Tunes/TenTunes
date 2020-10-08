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
    
    static  var defaultOutputDevice: UInt32? {
        var deviceID: AudioDeviceID = 0
        var propertyAddress = AudioObjectPropertyAddress()
        var propertySize: UInt32

        propertyAddress.mSelector = kAudioHardwarePropertyDefaultSystemOutputDevice
        propertyAddress.mScope = kAudioObjectPropertyScopeGlobal
        propertyAddress.mElement = 0
        propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let error = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                                     &propertyAddress,
                                                     0,
                                                     nil,
                                                     &propertySize,
                                                     &deviceID)
        
        if error != 0 {
            print("Could not get default device: \(error)")
            return nil
        }
        
        return deviceID
    }
}
