//
//  Library+Export.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library {
    func `import`(_ context: NSManagedObjectContext? = nil) -> Import {
        return Import(library: self, context: context ?? viewContext)
    }
    
    class Import {
        let library: Library
        let context: NSManagedObjectContext
        
        init(library: Library, context: NSManagedObjectContext) {
            self.library = library
            self.context = context
        }
    }
    
    func export(_ context: NSManagedObjectContext? = nil) -> Export {
        return Export(library: self, context: context ?? viewContext)
    }
    
    func startExport(completion: @escaping () -> Swift.Void) -> Bool {
        guard _exportChanged == nil || _exportChanged!.count > 0, exportSemaphore.acquireNow() else {
            return false
        }
        
        performBackgroundTask { mox in
            self.export(mox).updateExports()
            completion()
        }
        
        exportSemaphore.signalAfter(seconds: 60)
        
        return true
    }

    class Export {
        let library: Library
        let context: NSManagedObjectContext
        
        init(library: Library, context: NSManagedObjectContext) {
            self.library = library
            self.context = context
        }
        
        func url(title: String?, directory: Bool = true) -> URL {
            let exportsDirectory = library.directory.appendingPathComponent("Exports", isDirectory: true)
            return title != nil ? exportsDirectory.appendingPathComponent(title!, isDirectory: true) : exportsDirectory
        }
        
        func updateExports() {
            let changed = library._exportChanged
            library._exportChanged = Set()
            
            let tracks: [Track] = try! context.fetch(Track.fetchRequest())
            // TODO Sort playlist by their parent / child tree
            let playlists: [Playlist] = try! context.fetch(Playlist.fetchRequest())
            
            m3uPlaylists(playlists: playlists, changed: changed)
            iTunesLibraryXML(tracks: tracks, playlists: playlists)
            symlinks(tracks: tracks, playlists: playlists)
        }
        
        static func iterate<Type: Playlist>(playlists: [Type], changed: Set<NSManagedObjectID>?, in directory: URL, block: (URL, Type) -> Swift.Void) {
            // TODO Clean up old playlists
            for playlist in playlists where changed == nil || changed!.contains(playlist.objectID) || playlist.tracksList.anyMatch { changed!.contains($0.objectID) } {
                let url = Library.shared.url(of: playlist, relativeTo: directory)
                
                block(url, playlist)
            }
        }
    }
}
