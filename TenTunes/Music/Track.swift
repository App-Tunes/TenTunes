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
    static let pasteboardType = NSPasteboard.PasteboardType(rawValue: "tentunes.track")
    
    var id: Int = 0 // TODO Use proper UUIDs, save iTunes ID somewhere else
    var title: String? = nil
    var author: String? = nil
    var album: String? = nil
    var duration: CMTime? = nil

    var path: String? = nil
    var key: Key? = nil
    var bpm: Double? = nil
    
    var analysis: Analysis? = nil

    var artwork: NSImage? = nil

    var metadataFetched: Bool = false

    var rTitle: String {
        return title ?? "Unknown Title"
    }

    var rSource: String {
        return album != nil ? "\(rAuthor) - \(rAlbum)" : rAuthor
    }

    var rAuthor: String {
        return author ?? "Unknown Author"
    }

    var rAlbum: String {
        return album ?? ""
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
    
    var rLength: String {
        guard let duration = duration else {
            return ""
        }
        return Int(CMTimeGetSeconds(duration)).timeString
    }
    
    var url: URL? {
        get {
            if let url = path != nil ? URL(string: path!) : nil {
                return FileManager.default.fileExists(atPath: url.path) ? url : nil
            }
            return nil
        }
    }
    
    var searchable: [String] {
        return [rTitle, rAuthor, rAlbum]
    }
}

// Metadata

extension Track {
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
        duration = nil
        
        // TODO Length
        
        let importer = TagLibImporter.init(url: url)
        do {
            try importer?.import()
            
            self.title = importer?.title
            self.album = importer?.album
            self.author = importer?.artist
            
            self.artwork = importer?.image
            
            self.key = Key.parse(importer?.initialKey ?? "")
            self.bpm = Double(importer?.bpm ?? "")
        }
        catch let error {
            print(error)
        }
        
        let avImporter = AVFoundationImporter(url: url)
        
        title = title ?? avImporter.string(withKey: .commonKeyTitle, keySpace: .common)
        title = title ?? avImporter.string(withKey: .iTunesMetadataKeySongName, keySpace: .iTunes)
        
        album = album ?? avImporter.string(withKey: .commonKeyAlbumName, keySpace: .common)
        album = album ?? avImporter.string(withKey: .iTunesMetadataKeyAlbum, keySpace: .iTunes)
        
        author = author ?? avImporter.string(withKey: .commonKeyArtist, keySpace: .common)
        author = author ?? avImporter.string(withKey: .commonKeyCreator, keySpace: .common)
        author = author ?? avImporter.string(withKey: .commonKeyAuthor, keySpace: .common)
        author = author ?? avImporter.string(withKey: .iTunesMetadataKeyOriginalArtist, keySpace: .iTunes)
        author = author ?? avImporter.string(withKey: .iTunesMetadataKeyArtist, keySpace: .iTunes)
        author = author ?? avImporter.string(withKey: .iTunesMetadataKeySoloist, keySpace: .iTunes)
        
        artwork = artwork ?? avImporter.image(withKey: .commonKeyArtwork, keySpace: .common)
        artwork = artwork ?? avImporter.image(withKey: .iTunesMetadataKeyCoverArt, keySpace: .iTunes)
        
        bpm = bpm ?? Double(avImporter.string(withKey: .iTunesMetadataKeyBeatsPerMin, keySpace: .iTunes) ?? "")
        
        // For videos, generate thumbnails
        if self.artwork == nil {
            let imgGenerator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            do {
                let img = try imgGenerator.copyCGImage(at: CMTimeMake(0, 60), actualTime: nil)
                self.artwork = NSImage(cgImage: img, size: NSZeroSize)
            }
            catch {
                // print(err.localizedDescription)
            }
        }
        
        duration = duration ?? avImporter.duration
        
        //        var fileID: AudioFileID?
        //        if AudioFileOpenURL(url as CFURL, AudioFilePermissions.readPermission, 0, &fileID) == 0 {
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

extension Track : Equatable {
    static func ==(lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Track : Hashable {
    var hashValue: Int {
        return id.hashValue
    }
}

