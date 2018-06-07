//
//  AVFoundation+TT.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 06.06.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import AVFoundation

extension AVAudioPCMBuffer {
    var asData: Data {
        if let data16 = int16ChannelData {
            let channels = UnsafeBufferPointer(start: data16, count: 1)
            let ch0Data = Data(bytes: channels[0], count: Int(frameCapacity * format.streamDescription.pointee.mBytesPerFrame))
            
            return ch0Data
        }
        else if let data32 = int32ChannelData {
            let channels = UnsafeBufferPointer(start: data32, count: 1)
            let ch0Data = Data(bytes: channels[0], count: Int(frameCapacity * format.streamDescription.pointee.mBytesPerFrame))
            
            return ch0Data
        }
        else if let dataFloat = floatChannelData {
            let channels = UnsafeBufferPointer(start: dataFloat, count: 1)
            let ch0Data = Data(bytes: channels[0], count: Int(frameCapacity * format.streamDescription.pointee.mBytesPerFrame))
            
            return ch0Data
        }
        else {
            fatalError("Failed to determine format!")
        }
    }
}
