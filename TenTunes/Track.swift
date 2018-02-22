//
//  Track.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import AudioKit

class Track {
    var id: Int = 0
    var title: String? = nil
    var author: String? = nil
    var album: String? = nil
    var length: Int? = nil

    var path: String? = nil
    var key: Key? = nil
    var bpm: Int? = nil

    var rTitle: String {
        return title ?? "Unknown Title"
    }

    var rAuthor: String {
        return author ?? "Unknown Author"
    }

    var rAlbum: String {
        return album ?? "Unknown Album"
    }
    
    var rKey: NSAttributedString {
        guard let key = self.key else {
            return NSAttributedString(string: "")
        }
        
        return key.description
    }
    
    var rArtwork: NSImage {
        return self.artwork ?? NSImage(named: NSImage.Name(rawValue: "music_missing"))!
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    var rLength: String {
        guard let length = self.length else {
            return "??:??"
        }
        let (h, m, s) = secondsToHoursMinutesSeconds(seconds: length / 1000)
        return String(format: "\(m):%02d", s)
    }
    
    var url: URL? {
        get {
            return path != nil ? URL(string: path!) : nil
        }
    }
    
    var metadataFetched: Bool = false
    var artwork: NSImage? = nil

    func fetchMetadata() {
        self.metadataFetched = true
        self.artwork = nil

        guard let url = self.url else {
            return
        }
        
        let urlAsset = AVURLAsset(url: url)
        
        self.fetchArtwork(asset: urlAsset)
        self.fetchID3(asset: urlAsset)
        self.fetchTitle(asset: urlAsset)

        return
    }
    
    func fetchTitle(asset: AVURLAsset) {
        for metadata in AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common) {
            if let title = metadata.stringValue {
                self.title = title
                return
            }
        }

        for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.id3MetadataKeyTitleDescription, keySpace: AVMetadataKeySpace.id3) {
            if let title = metadata.stringValue {
                self.title = title
                return
            }
        }
}

    func fetchID3(asset: AVURLAsset) {
        for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.id3MetadataKeyInitialKey, keySpace: AVMetadataKeySpace.id3) {
            if let key = metadata.stringValue {
                self.key = Key.parse(string: key)
            }
        }

        for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.id3MetadataKeyBeatsPerMinute, keySpace: AVMetadataKeySpace.id3) {
            if let bpm = metadata.stringValue {
                self.bpm = Int(bpm)
            }
        }
    }

    func fetchArtwork(asset: AVURLAsset) {
        for metadata in AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common) {
            if let data = metadata.dataValue {
                print("Found 1")
                self.artwork = NSImage(data: data)
                return
            }
            else {
                print("Fail 1")
            }
        }
        
        for metadata in AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.iTunesMetadataKeyCoverArt, keySpace: AVMetadataKeySpace.iTunes) {
            if let data = metadata.dataValue {
                print("Found 2")
                self.artwork = NSImage(data: data)
                return
            }
            else {
                print("Fail 2")
            }
        }
    }
}
