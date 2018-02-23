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
    
    func string(withKey: AVMetadataKey, keySpace: AVMetadataKeySpace) -> String? {
        for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: withKey, keySpace: keySpace) {
            if let val = metadata.stringValue {
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
