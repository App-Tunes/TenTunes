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
        
        title = nil
        key = nil
        bpm = nil
        artwork = nil
        
        // TODO Author, Album, Length

        let importer = JUKImporter.init(url: self.url!)
        do {
            try importer?.import()
            if let img = importer?.image {
                self.artwork = img
            }
            if let key = importer?.initialKey {
                self.key = Key.parse(key)
            }
            if let bpm = importer?.bpm {
                self.bpm = Int(bpm)
            }
        }
        catch let error {
            print(error)
        }
        
        let avImporter = AVFoundationImporter(url: self.url!)
        
        title = title ?? avImporter.string(withKey: .commonKeyTitle, keySpace: .common)
        title = title ?? avImporter.string(withKey: .id3MetadataKeyTitleDescription, keySpace: .id3)
        
        key = key ?? Key.parse(avImporter.string(withKey: .id3MetadataKeyInitialKey, keySpace: .id3) ?? "")
        
        bpm = bpm ?? Int(avImporter.string(withKey: .id3MetadataKeyBeatsPerMinute, keySpace: .id3) ?? "")

        artwork = artwork ?? avImporter.image(withKey: .commonKeyArtwork, keySpace: .common)
        artwork = artwork ?? avImporter.image(withKey: .iTunesMetadataKeyCoverArt, keySpace: .iTunes)

        // For videos, generate thumbnails
        if self.artwork == nil {
            let imgGenerator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            do {
                let img = try imgGenerator.copyCGImage(at: CMTimeMake(0, 60), actualTime: nil)
                self.artwork = NSImage(cgImage: img, size: NSZeroSize)
                print("Generated thumbnail for " + path!)
            }
            catch {
                // print(err.localizedDescription)
            }
        }

//        var fileID: AudioFileID?
//        if AudioFileOpenURL(self.url! as CFURL, AudioFilePermissions.readPermission, 0, &fileID) == 0 {
//            var size: UInt32 = 0
//            var data: CFData? = nil
//            let err = AudioFileGetProperty(fileID!, kAudioFilePropertyAlbumArtwork, &size, &data)
//            if err != 0 {
//                print(err)
//            }
//            else {
//                print("Sucks ass")
//            }
//            AudioFileClose(fileID!)
//        }

//        for track in asset.tracks {
//            print(track)
//            for desc in track.formatDescriptions {
//                print(desc)
//            }
//        }
//
//        for track in asset.allMediaSelections {
//            print(track)
//        }

        return
    }
}
