//
//  CategoryController+Categories.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension CategoryController.Item {
    class AlbumItem : CategoryController.Category {
        let album: Album
        
        init(_ album: Album) {
            self.album = album
        }
        
        lazy var _artwork = Album.artworkPreview(tracks)
        
        override var title: String { return album.title }
        override var subtitle: String { return Artist.describe(album.author) }

        override var icon: NSImage { return _artwork }
        
        override var tracks: [Track] { return album.tracks }
    }

    class GenreItem : CategoryController.Category {
        let genre: Genre
        
        init(_ genre: Genre) {
            self.genre = genre
        }
        
        override var title: String { return genre.name }
        override var subtitle: String {
            return AppDelegate.defaults.describe(trackCount: tracks.count)
        }

        override var icon: NSImage { return NSImage(named: .genreName)! }
        
        override var tracks: [Track] { return genre.tracks }
    }

    class ArtistItem : CategoryController.Category {
        let artist: Artist
        
        init(_ artist: Artist) {
            self.artist = artist
        }
        
        override var title: String { return artist.name }
        override var subtitle: String {
            return AppDelegate.defaults.describe(trackCount: tracks.count)
        }
        
        override var icon: NSImage { return NSImage(named: .artistName)! }
        
        override var tracks: [Track] { return artist.tracks }
    }
}
