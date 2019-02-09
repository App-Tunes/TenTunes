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
        super.execute()

        let library = Library.shared
        performChildBackgroundTask(for: library) { [unowned self] mox in
            let playlists = mox.compactConvert(self.playlists)
            
            let pather = self.libraryURL == library.mediaLocation.directory
                ? library.mediaLocation.pather()
                : MediaLocation.pather(for: self.libraryURL)
            
            Library.Export.remoteM3uPlaylists(playlists, to: self.destinationURL, pather: pather)
            Library.Export.remoteSymlinks(playlists, to: self.aliasURL, pather: pather)
            
            // TODO Alert if some files were missing
            
            self.finish()
        }
    }
}
