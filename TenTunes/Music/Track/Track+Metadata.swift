//
//  Track+Metadata.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import CoreAudioKit

fileprivate func parseGenre(_ genre: String?) -> String? {
    return genre == "Unknown" ? nil : genre
}

extension Track {
    enum MetadataError: Error {
        case fileNotFound
    }
    
    func fetchMetadata(force: Bool = false) throws {
        guard let url = self.liveURL, let modDate = liveFileAttributes?[.modificationDate] as! Date? else {
            throw MetadataError.fileNotFound
        }
        
        guard force || (metadataFetchDate.map(modDate.isAfter) ?? true) else {
            // Hasn't changed
            return
        }
        
        self.metadataFetchDate = Date()

        let prevTitle = title
        let prevAlbum = album
        let prevAuthor = author
        
        let prevGenre = genre
        let prevKeyString = keyString
        let prevBPM = speed
        
        var artwork: NSImage?

        // TODO Duration
        
        if let tagLibFile = tagLibFile {
            title = tagLibFile.title
            album = tagLibFile.album
            author = tagLibFile.artist
            
            albumArtist = tagLibFile.band // Used this way by other editors e.g. iTunes
            remixAuthor = tagLibFile.remixArtist
            
            genre = parseGenre(tagLibFile.genre)
            
            artwork = tagLibFile.image.flatMap { NSImage(data: $0) }
            
            keyString = tagLibFile.initialKey
            bpmString = tagLibFile.bpm
            
            // "Nullable" -> 0 = nil anyway
            year = Int16(tagLibFile.year)
            trackNumber = Int16(tagLibFile.trackNumber)
            
            comments = tagLibFile.comments as NSString?
            
//            duration = CMTime(seconds: Double(tagLibFile.durationInMilliseconds) / 1000.0, preferredTimescale: 1000)
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
                let img = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 60), actualTime: nil)
                artwork = NSImage(cgImage: img, size: NSZeroSize)
            }
            catch {
                // print(err.localizedDescription)
            }
        }
        
        let avDuration = avImporter.duration
        duration = avDuration.seconds.isNormal ? avDuration : duration
        
        var bitrate = avImporter.bitrate.map(Float.init)
        if bitrate == nil || bitrate == 0, let filesize = try? FileManager.default.sizeOfItem(at: url), let duration = self.duration {
            // Guess based on file size and channels
            // According to Wikipedia, all channels count, so no divide by avImporter.channels
            bitrate = Float(Double(filesize) * 8 / duration.seconds)
        }
        self.bitrate = bitrate ?? self.bitrate
        
        // Some files don't store metadata at all; if we can't read these then use the values we had previously
        title = title ?? prevTitle
        album = album ?? prevAlbum
        author = author ?? prevAuthor
        
        genre = genre ?? prevGenre
        keyString = keyString ?? prevKeyString
        speed = speed ?? prevBPM
        
        // Also generate if artwork is nil since preview gets set to nil then too
        forcedVisuals.artworkPreview = Album.preview(for: artwork)
    }
        
    enum MetadataWriteError : Error {
        case noPath, fileNotFound
    }
    
    func writeMetadata(values: [PartialKeyPath<Track>]) throws {
        guard !values.isEmpty else {
            return
        }
        
        guard path != nil else {
            throw MetadataWriteError.noPath
        }
        
        guard let tagLibFile = self.tagLibFile else {
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

            case \Track.comments:
                tagLibFile.comments = comments as String?
                
            default:
                fatalError("Unwriteable Path: \(path)")
            }
        }
        
        try tagLibFile.write()
    }
}
