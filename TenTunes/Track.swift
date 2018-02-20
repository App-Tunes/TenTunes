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
    
     lazy var _artwork: LazyVar<NSImage?> = LazyVar() {
        guard let url = self.url else {
            return nil
        }
        
        let urlAsset = AVURLAsset(url: url)
        for format in urlAsset.availableMetadataFormats {
            for metadata in urlAsset.metadata(forFormat: format) {
                if let commonKey = metadata.commonKey {
                    if commonKey.rawValue == "artwork" {
                        if let data = metadata.dataValue {
                            return NSImage(data: data)
                        }
                    }
                }
            }
        }
        return nil
    }
    
    var artwork: NSImage? {
        return _artwork.value
    }
    
    func fetchArtwork(completion: @escaping (NSImage?) -> Swift.Void) {
        _artwork.async(completion: completion)
    }
}
