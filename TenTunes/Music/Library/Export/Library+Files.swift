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
    
    struct FileTypes: OptionSet {
        let rawValue: Int
        
        static let track = FileTypes(rawValue: 1 << 0)
        static let playlist = FileTypes(rawValue: 1 << 1)
    }
    
    class Import {
        let library: Library
        let context: NSManagedObjectContext
        
        init(library: Library, context: NSManagedObjectContext) {
            self.library = library
            self.context = context
        }
        
        class func dialogue(allowedFiles: Library.FileTypes) -> NSOpenPanel {
            // TODO honor the parameter
            let dialog = NSOpenPanel()
            
            dialog.allowsMultipleSelection = true
            
            dialog.canChooseDirectories = false
            dialog.canCreateDirectories = false
            
            return dialog
        }
        
        func guess(url: URL) -> AnyObject? {
            if url.lastPathComponent.hasSuffix(".m3u") {
                return m3u(url: url)
            }
            
            return track(url: url) // TODO Only if audiovisual
        }
    }
    
    func export(_ context: NSManagedObjectContext? = nil) -> Export {
        return Export(library: self, context: context ?? viewContext)
    }
    
    func considerExport() {
        guard _exportChanged == nil || _exportChanged!.count > 0, exportSemaphore.acquireNow() else {
            return
        }
        
        ViewController.shared.tasker.enqueue(task: UpdateExports(library: self))
    }
        
    class UpdateExports: Task {
        let library: Library
        
        init(library: Library) {
            self.library = library
            super.init(priority: 2)
        }
        
        override var title: String { return "Update Exports" }
        
        override var preventsQuit: Bool { return false }
        
        override func execute() {
            super.execute()

            library.performBackgroundTask { [unowned self] mox in
                self.library.export(mox).updateExports()
                self.finish()
            }
        }
        
        override func finish() {
            super.finish()
            
            library.exportSemaphore.signalAfter(seconds: 30)
        }
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
            
            if changed == nil {
                // Full wipe, we're expected to start over
                try? FileManager.default.removeItem(at: url(title: nil))
            }
            
            let tracks: [Track] = (try! context.fetch(Track.fetchRequest()))
            
            (try! context.fetch(Playlist.fetchRequest())) // Pre-Grab all the playlists for performance reasons
            let playlists: [Playlist] = [context.convert(library.masterPlaylist)!].flatten { ($0 as? PlaylistFolder)?.childrenList }

            m3uPlaylists(playlists: playlists, changed: changed)
            iTunesLibraryXML(tracks: tracks, playlists: playlists)
            symlinks(tracks: tracks, playlists: playlists)
        }
        
        static func iterate<Type: Playlist>(playlists: [Type], changed: Set<NSManagedObjectID>?, in directory: URL, block: (URL, Type) -> Swift.Void) {
            // TODO Clean up old playlists
            for playlist in playlists where changed == nil || changed!.contains(playlist.objectID) || playlist.tracksList.anySatisfy { changed!.contains($0.objectID) } {
                guard playlist.fireFault() else {
                    continue
                }
                
                let url = Library.shared.url(of: playlist, relativeTo: directory)
                block(url, playlist)
            }
        }
    }
}
