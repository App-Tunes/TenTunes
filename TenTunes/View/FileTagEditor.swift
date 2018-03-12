//
//  FileTagEditor.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class FileTagEditor: NSWindowController {
        
    var context: NSManagedObjectContext!
    @objc dynamic var tracks: [Track] = [] {
        didSet {
            for track in tracks where !track.metadataFetched {
                track.fetchMetadata()
            }
        }
    }
    @IBOutlet var tracksController: NSArrayController!
    
    convenience init() {
        self.init(windowNibName: .init("FileTagEditor"))
        window!.level = .floating
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    func show(tracks: [Track]) {
        context = Library.shared.persistentContainer.newBackgroundContext()
        self.tracks = tracks.map(context.convert)
        
        showWindow(self)
        window!.becomeKey()
    }
    
    @IBAction func save(_ sender: Any) {
        Library.shared.save(in: context)
        for track in tracks {
            track.writeMetadata()
        }
        
        ViewController.shared.reloadFor(tracks: tracks.map(Library.shared.viewMox.convert) )
        window?.close()
    }
    
    @IBAction func cancel(_ sender: Any) {
        window?.close()
    }
}

class FileTagEditorWindow: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
}
