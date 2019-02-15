//
//  ExportPlaylists.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class ExportPlaylists: Task {
    let tracksURL: URL
    let playlists: [Playlist]
    
    var destinationURL: URL? = nil
    var aliasURL: URL? = nil
    var libraryURL: URL? = nil

    init(tracksURL: URL, playlists: [Playlist]) {
        self.tracksURL = tracksURL
        self.playlists = playlists
    }
    
    override var title: String { return "Exporting Playlists" }
    
    override func execute() {
        super.execute()

        let library = Library.shared
        performChildBackgroundTask(for: library) { [unowned self] mox in
            let playlists = mox.compactConvert(self.playlists)
            
            let pather = self.tracksURL == library.mediaLocation.directory
                ? library.mediaLocation.pather()
                : MediaLocation.pather(for: self.tracksURL)
            
            if let libraryURL = self.libraryURL {
                try! FileManager.default.removeItem(at: libraryURL)
                Library.shared.export(mox).remoteLibrary(playlists, to: libraryURL, pather: pather)
            }

            if let destinationURL = self.destinationURL {
                try! FileManager.default.removeItem(at: destinationURL)
                Library.Export.remoteM3uPlaylists(playlists, to: destinationURL, pather: pather)
            }
            
            if let aliasURL = self.aliasURL {
                try! FileManager.default.removeItem(at: aliasURL)
                Library.Export.remoteSymlinks(playlists, to: aliasURL, pather: pather)
            }
            
            // TODO Alert if some files were missing
            
            self.finish()
        }
    }
}
