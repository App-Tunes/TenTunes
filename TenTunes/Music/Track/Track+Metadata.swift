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
        
        var title: String? = nil
        var album: String? = nil
        var author: String? = nil
        var genre: String? = nil
        var key: Key? = nil
        var bpm: Double? = nil
        var artwork: NSImage? = nil
        
        // TODO Duration
        
        let importer = TagLibImporter(url: url)
        do {
            try importer.import()
            
            title = importer.title
            album = importer.album
            author = importer.artist
            genre = parseGenre(importer.genre)
            
            artwork = importer.image
            
            key = Key.parse(importer.initialKey ?? "")
            bpm = Double(importer.bpm ?? "")
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
        
        genre = genre ?? parseGenre(avImporter.string(withKey: .iTunesMetadataKeyUserGenre, keySpace: .iTunes))
        genre = genre ?? parseGenre(avImporter.string(withKey: .iTunesMetadataKeyPredefinedGenre, keySpace: .iTunes))
        
        artwork = artwork ?? avImporter.image(withKey: .commonKeyArtwork, keySpace: .common)
        artwork = artwork ?? avImporter.image(withKey: .iTunesMetadataKeyCoverArt, keySpace: .iTunes)
        
        bpm = bpm ?? Double(avImporter.string(withKey: .iTunesMetadataKeyBeatsPerMin, keySpace: .iTunes) ?? "")
        
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
        
        bitrate = (avImporter.bitrate ?=> Float.init) ?? 0
        
        if analysis == nil {
            readAnalysis()
        }
        
        // Always prefer the data we read if any
        self.title = title ?? self.title
        self.album = album ?? self.album
        self.author = author ?? self.author
        self.genre = genre ?? self.genre
        self.key = key ?? self.key
        self.bpm = bpm ?? self.bpm
        self.artwork = artwork ?? self.artwork
        
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
            importer.artist = author
            importer.genre = genre
            
            importer.initialKey = keyString
            importer.bpm = bpmString
            
            try importer.write()
            // TODO Artwork
        }
        catch let error {
            print(error)
        }
    }
}
