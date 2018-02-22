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
    var title: String? = nil
    var author: String? = nil
    var album: String? = nil
    var length: Int? = nil

    var path: String? = nil
    var key: Key? = nil

    func rTitle() -> String {
        return title ?? "Unknown Title"
    }

    func rAuthor() -> String {
        return author ?? "Unknown Author"
    }

    func rAlbum() -> String {
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
    
    func rLength() -> String {
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
        self.fetchKey(asset: urlAsset)

        return
    }

    func fetchKey(asset: AVURLAsset) {
        let metadatas = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.id3MetadataKeyInitialKey, keySpace: AVMetadataKeySpace.id3)
        
        for metadata in metadatas {
            if let key = metadata.stringValue {
                self.key = Key.parse(string: key)
                return
            }
        }
    }

    func fetchArtwork(asset: AVURLAsset) {
        var metadatas = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common)

        for metadata in metadatas {
            if let data = metadata.dataValue {
                print("Found 1")
                self.artwork = NSImage(data: data)
                return
            }
            else {
                print("Fail 1")
            }
        }
        
        metadatas = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.iTunesMetadataKeyCoverArt, keySpace: AVMetadataKeySpace.iTunes)
        
        for metadata in metadatas {
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
