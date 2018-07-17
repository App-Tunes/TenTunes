//
//  ExportPlaylists.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class ExportPlaylists: Task {
    let libraryURL: URL
    let playlists: [Playlist]
    
    let destinationURL: URL
    let aliasURL: URL
    
    init(libraryURL: URL, playlists: [Playlist], destinationURL: URL, aliasURL: URL) {
        self.libraryURL = libraryURL
        self.playlists = playlists
        
        self.destinationURL = destinationURL
        self.aliasURL = aliasURL
    }
    
    override var title: String { return "Exporting Playlists" }
    
    override func execute() {
        let pather = libraryURL == Library.shared.mediaLocation.directory ? Library.shared.mediaLocation.pather() : MediaLocation.pather(for: libraryURL)
        
        Library.Export.remoteM3uPlaylists(playlists, to: destinationURL, pather: pather)
        Library.Export.remoteSymlinks(playlists, to: aliasURL, pather: pather)
        
        // TODO Alert if some files were missing
    }
}
