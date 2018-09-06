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
    
    init(title: String, by author: Artist?) {
        self.title = title
        self.author = author
    }
    
    var tracks: [Track] {
        return Library.shared.allTracks.tracksList.filter { $0.rAlbum == self }
    }
    
    static func preview(for artwork: NSImage?) -> NSImage? {
        return artwork?.resized(w: 64, h: 64)
    }
    
    var artwork: NSImage? {
        get { return tracks.compactMap { $0.artwork }.first ?? Album.missingArtwork }
        set {
            let data = newValue?.jpgRepresentation
            let preview = Album.preview(for: newValue)
            for track in tracks {
                track.forcedVisuals.artwork = data as NSData?
                track.forcedVisuals.artworkPreview = preview
            }
        }
    }
    
    var artworkData: NSData? {
        get { return tracks.compactMap { $0.visuals?.artwork }.first }
        set { tracks.forEach { $0.forcedVisuals.artwork = newValue } }
    }
    
    var artworkPreview: NSImage? {
        get { return tracks.compactMap { $0.artworkPreview }.first ?? Album.missingArtwork }
    }
    
    func writeMetadata() throws {
        for track in tracks {
            try track.writeMetadata(values: [\Track.artwork])
        }
    }
}

extension Album : Hashable {
    var hashValue: Int {
        return title.lowercased().hashValue ^ (author?.hashValue ?? 0)
    }
    
    static func == (lhs: Album, rhs: Album) -> Bool {
        return lhs.title.lowercased() == rhs.title.lowercased() &&
            lhs.author == rhs.author
    }
}
