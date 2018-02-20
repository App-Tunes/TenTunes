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
    
    func rTitle() -> String {
        return title ?? "Unknown Title"
    }

    func rAuthor() -> String {
        return author ?? "Unknown Author"
    }

    func rAlbum() -> String {
        return album ?? "Unknown Album"
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
    
    var artworkFetched: Bool = false
    var artwork: NSImage? = nil

    func fetchArtwork() -> NSImage? {
        self.artworkFetched = true
        self.artwork = nil

        guard let url = self.url else {
            return nil
        }
        
        let urlAsset = AVURLAsset(url: url)

        let metadatas = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common)
        
        for metadata in metadatas {
            if let data = metadata.dataValue {
                self.artwork = NSImage(data: data)
                return self.artwork
            }
        }
        
        return nil
    }
}
