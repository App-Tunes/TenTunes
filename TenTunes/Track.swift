//
//  Track.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

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
}
