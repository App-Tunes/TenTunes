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
        
        let importer = TagLibImporter(url: url)
        do {
            try importer.import()
            
            title = importer.title
            album = importer.album
            author = importer.artist

            albumArtist = importer.albumArtist
            remixAuthor = importer.remixArtist
            
            genre = parseGenre(importer.genre)
            
            artwork = importer.image
            
            keyString = importer.initialKey
            bpmString = importer.bpm
            
            // "Nullable" -> 0 = nil anyway
            year = importer.year
            trackNumber = importer.trackNumber
        }
        catch let error {
            print(error)
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
    
    func writeMetadata() {
        guard let url = self.url else {
            print("Tried to write to track without file!")
            return
        }
        
        let importer = TagLibImporter(url: url)
        
        do {
            importer.title = title
            
            importer.album = album
            importer.albumArtist = albumArtist
            importer.artist = author
            importer.remixArtist = remixAuthor

            importer.genre = genre
            
            importer.initialKey = keyString
            importer.bpm = bpmString
            importer.year = year
            importer.trackNumber = trackNumber

            try importer.write()
            // TODO Artwork
        }
        catch let error {
            print(error)
        }
    }
}
