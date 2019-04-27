//
//  Album.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Album {
    static let unknown = "Unknown Album"
    static let missingArtwork = #imageLiteral(resourceName: "music_missing")

    let title: String
    let author: Artist?
    var _tracks: [Track]?
    
    init(title: String, by author: Artist?, tracks: [Track]) {
        self.title = title
        self.author = author
        self._tracks = tracks
    }
    
    init(title: String, by author: Artist?) {
        self.title = title
        self.author = author
    }
    
    static func preview(for artwork: NSImage?) -> NSImage? {
        return artwork?.resized(w: 64, h: 64)
    }
    
    static func artwork(_ tracks: [Track]) -> NSImage {
        return tracks.compactMap { $0.artwork }.first ?? Album.missingArtwork
    }
    
    var tracks: [Track] {
        if _tracks == nil {
            _tracks = Library.shared.allTracks().filter { $0.rAlbum == self }
        }
        return _tracks!
    }
    
    var artwork: NSImage? {
        get { return Album.artwork(tracks) }
        set {
            let data = newValue?.jpgRepresentation
            let preview = Album.preview(for: newValue)
            for track in tracks {
                track.artworkData = data
                track.forcedVisuals.artworkPreview = preview
            }
        }
    }
    
    var artworkData: Data? {
        get { return tracks.compactMap { $0.artworkData }.first }
        set { tracks.forEach { $0.artworkData = newValue } }
    }
    
    static func artworkPreview(_ tracks: [Track]) -> NSImage {
        return tracks.compactMap { $0.artworkPreview }.first ?? Album.missingArtwork
    }
    
    var artworkPreview: NSImage? {
        get { return Album.artworkPreview(tracks) }
    }
    
    var year: Int16 {
        get { return tracks.compactMap { $0.year }.filter { $0 > 0 }.first ?? 0 }
        set { tracks.forEach { $0.year = newValue }}
    }
    
    var publisher: String? {
        get { return tracks.compactMap { $0.publisher }.first }
        set { tracks.forEach { $0.publisher = newValue } }
    }
    
    var albumNumberOfCDs: Int {
        get { return tracks.compactMap { $0.albumNumberOfCDs }.filter { $0 > 0 }.first ?? 0 }
        set { tracks.forEach { $0.albumNumberOfCDs = newValue }}
    }

//    var setLength: Int? {
//        get { return tracks.compactMap { $0.partOfSet }.first }
//    }
    
    func writeMetadata(values: [PartialKeyPath<Track>]) throws {
        for track in tracks {
            try track.writeMetadata(values: values)
        }
    }
}

extension Album : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title.lowercased())
        hasher.combine(author)
    }
    
    static func == (lhs: Album, rhs: Album) -> Bool {
        return lhs.title.caseInsensitiveCompare(rhs.title) == .orderedSame &&
            lhs.author == rhs.author
    }
}

extension Album : Comparable {
    static func < (lhs: Album, rhs: Album) -> Bool {
        return lhs.title < rhs.title
    }
}
