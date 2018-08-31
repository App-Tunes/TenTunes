//
//  Track+Metadata.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import AudioKit

fileprivate func parseGenre(_ genre: String?) -> String? {
    return genre == "Unknown" ? nil : genre
}

extension Track {
    enum MetadataError: Error {
        case fileNotFound
    }
    
    func fetchMetadata() throws {
        self.metadataFetched = true
        self.artwork = nil
        
        guard let url = self.url else {
            throw MetadataError.fileNotFound
        }
        
        let prevTitle = title
        let prevAlbum = album
        let prevAuthor = author
        
        let prevGenre = genre
        let prevKeyString = keyString
        let prevBPM = speed

        // TODO Duration
        
        if let tagLibFile = TagLibFile(url: url) {
            title = tagLibFile.title
            album = tagLibFile.album
            author = tagLibFile.artist
            
            albumArtist = tagLibFile.band // Used this way by other editors e.g. iTunes
            remixAuthor = tagLibFile.remixArtist
            
            genre = parseGenre(tagLibFile.genre)
            
            artwork = tagLibFile.image
            
            keyString = tagLibFile.initialKey
            bpmString = tagLibFile.bpm
            
            // "Nullable" -> 0 = nil anyway
            year = Int16(tagLibFile.year)
            trackNumber = Int16(tagLibFile.trackNumber)
            
            comments = tagLibFile.comments as NSString?
        }
        else {
            print("Failed to load TagLibFile for \(url)")
        }
        
        let avImporter = AVFoundationImporter(url: url)
        
        title = title ?? avImporter.string(withKey: .commonKeyTitle, keySpace: .common)
        title = title ?? avImporter.string(withKey: .iTunesMetadataKeySongName, keySpace: .iTunes)
        
        album = album ?? avImporter.string(withKey: .commonKeyAlbumName, keySpace: .common)
        album = album ?? avImporter.string(withKey: .iTunesMetadataKeyAlbum, keySpace: .iTunes)

        albumArtist = albumArtist ?? avImporter.string(withKey: .iTunesMetadataKeyAlbumArtist, keySpace: .iTunes)

        author = author ?? avImporter.string(withKey: .commonKeyArtist, keySpace: .common)
        author = author ?? avImporter.string(withKey: .commonKeyCreator, keySpace: .common)
        author = author ?? avImporter.string(withKey: .commonKeyAuthor, keySpace: .common)
        author = author ?? avImporter.string(withKey: .iTunesMetadataKeyOriginalArtist, keySpace: .iTunes)
        author = author ?? avImporter.string(withKey: .iTunesMetadataKeyArtist, keySpace: .iTunes)
        author = author ?? avImporter.string(withKey: .iTunesMetadataKeySoloist, keySpace: .iTunes)
        
        genre = genre ?? parseGenre(avImporter.string(withKey: .iTunesMetadataKeyUserGenre, keySpace: .iTunes))
        genre = genre ?? parseGenre(avImporter.string(withKey: .iTunesMetadataKeyPredefinedGenre, keySpace: .iTunes))
        
        artwork = artwork ?? avImporter.image(withKey: .commonKeyArtwork, keySpace: .common)
        artwork = artwork ?? avImporter.image(withKey: .iTunesMetadataKeyCoverArt, keySpace: .iTunes)
        
        bpmString = bpmString ?? avImporter.string(withKey: .iTunesMetadataKeyBeatsPerMin, keySpace: .iTunes)

        // For videos, generate thumbnails
        if artwork == nil {
            let imgGenerator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            do {
                let img = try imgGenerator.copyCGImage(at: CMTimeMake(0, 60), actualTime: nil)
                artwork = NSImage(cgImage: img, size: NSZeroSize)
            }
            catch {
                // print(err.localizedDescription)
            }
        }
        
        duration = avImporter.duration
        
        var bitrate = avImporter.bitrate ?=> Float.init
        if bitrate == nil || bitrate == 0, let filesize = try? FileManager.default.sizeOfItem(at: url) {
            // Guess based on file size and channels
            bitrate = Float(Double(filesize) * 8 / avImporter.duration.seconds / avImporter.channels)
        }
        self.bitrate = bitrate ?? self.bitrate
        
        if analysis == nil {
            readAnalysis()
        }
        
        // Some files don't store metadata at all; if we can't read these then use the values we had previously
        title = title ?? prevTitle
        album = album ?? prevAlbum
        author = author ?? prevAuthor
        
        genre = genre ?? prevGenre
        keyString = keyString ?? prevKeyString
        speed = speed ?? prevBPM

        if let artwork = artwork {
            self.artworkPreview = artwork.resized(w: 64, h: 64)
            // TODO Write both to data
        }
    }
    
    enum MetadataWriteError : Error {
        case noPath, fileNotFound
    }
    
    func writeMetadata(values: [PartialKeyPath<Track>]) throws {
        guard !values.isEmpty else {
            return
        }
        
        guard let url = self.url else {
            throw MetadataWriteError.noPath
        }
        
        guard let tagLibFile = TagLibFile(url: url) else {
            throw MetadataWriteError.fileNotFound
        }
        
        for path in values {
            switch path {
            case \Track.title:
                tagLibFile.title = title
                
            case \Track.album:
                tagLibFile.album = album
            case \Track.author:
                tagLibFile.artist = author
            case \Track.albumArtist:
                tagLibFile.band = albumArtist
            case \Track.remixAuthor:
                tagLibFile.remixArtist = remixAuthor

            case \Track.genre:
                tagLibFile.genre = genre

            case \Track.keyString:
                tagLibFile.initialKey = keyString
            case \Track.bpmString:
                tagLibFile.bpm = bpmString

            case \Track.year:
                tagLibFile.year = UInt32(year)
            case \Track.trackNumber:
                tagLibFile.trackNumber = UInt32(trackNumber)

            case \Track.trackNumber:
                tagLibFile.comments = comments as String?

            default:
                fatalError("Unwriteable Path: \(path)")
            }
        }
        
        try tagLibFile.write()
        // TODO Artwork
    }
}
