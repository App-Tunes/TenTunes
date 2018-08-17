//
//  AVFoundationImporter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation

class AVFoundationImporter {
    var asset: AVAsset
    
    init(url: URL) {
        self.asset = AVURLAsset(url: url)
    }
    
    var duration: CMTime {
        return asset.duration
    }
    
    var bitrate: Float64? {
        let track = asset.tracks[0]
        let desc = track.formatDescriptions[0] as! CMAudioFormatDescription
        guard let info = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee else {
            return nil
        }
        return Float64(info.mBitsPerChannel) * info.mSampleRate
    }
    
    var channels: Int {
        let track = asset.tracks[0]
        let desc = track.formatDescriptions[0] as! CMAudioFormatDescription
        guard let info = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee else {
            print("Guessed Channel number!")
            return 1 // Guess, but shouldn't happen .... :>
            // (It does, though... lol)
        }
        return Int(info.mChannelsPerFrame)
    }
    
    func string(withKey: AVMetadataKey, keySpace: AVMetadataKeySpace) -> String? {
        for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: withKey, keySpace: keySpace) {
            if let val = metadata.stringValue {
                return val
            }
        }
        return nil
    }
    
    func number(withKey: AVMetadataKey, keySpace: AVMetadataKeySpace) -> NSNumber? {
        for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: withKey, keySpace: keySpace) {
            if let val = metadata.numberValue {
                return val
            }
        }
        return nil
    }
    
    func data(withKey: AVMetadataKey, keySpace: AVMetadataKeySpace) -> Data? {
        for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: withKey, keySpace: keySpace) {
            if let val = metadata.dataValue {
                return val
            }
        }
        return nil
    }
    
    func image(withKey: AVMetadataKey, keySpace: AVMetadataKeySpace) -> NSImage? {
        if let data = data(withKey: withKey, keySpace: keySpace) {
            if let img = NSImage(data: data) {
                return img
            }
            else {
                print("Failed to read image from data")
            }
        }
        return nil
    }
}
