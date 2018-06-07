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
        return withUnsafePointer {
            return Data(bytes: $0, count: $1)
        }
    }
    
    func withUnsafePointer<Return>(block: (UnsafeRawPointer, Int) -> Return) -> Return {
        var pointer: UnsafeRawPointer
        
        if let data16 = int16ChannelData {
            pointer = UnsafeRawPointer(UnsafeBufferPointer(start: data16, count: 1)[0])
        }
        else if let data32 = int32ChannelData {
            pointer = UnsafeRawPointer(UnsafeBufferPointer(start: data32, count: 1)[0])
        }
        else if let dataFloat = floatChannelData {
            pointer = UnsafeRawPointer(UnsafeBufferPointer(start: dataFloat, count: 1)[0])
        }
        else {
            fatalError("Failed to determine format!")
        }
        
        let length = Int(frameCapacity * format.streamDescription.pointee.mBytesPerFrame)
        return block(pointer, length)
    }
}
