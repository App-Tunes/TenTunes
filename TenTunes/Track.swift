//
//  Track.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import AudioKit

struct Track {
    var title: String?
    var author: String?
    var album: String?

    var path: String?
    
    func rTitle() -> String {
        return title ?? "Unknown Title"
    }

    func rAuthor() -> String {
        return author ?? "Unknown Author"
    }

    func rAlbum() -> String {
        return album ?? "Unknown Album"
    }
    
    var url: URL {
        get {
            return URL(string: path!)!
        }
    }
    
    var artwork: NSImage? {
        get {
            let urlAsset = AVURLAsset(url: self.url)
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
    }
}
