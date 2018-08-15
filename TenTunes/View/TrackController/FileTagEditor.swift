//
//  FileTagEditor.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class FileTagEditor: NSViewController {
        
    var context: NSManagedObjectContext!
    @objc dynamic var tracks: [Track] = [] {
        didSet {
            for track in tracks {
                try! track.fetchMetadata()
            }
            
            Library.shared.mediaLocation.updateLocations(of: tracks)
        }
    }
    @IBOutlet var tracksController: NSArrayController!
    
    var manyTracks: [Track] = []
    
    @IBOutlet var _contentView: NSView!
    @IBOutlet var _manyPlaceholder: NSView!
    @IBOutlet var _nonePlaceholder: NSView!
    
    override func viewDidLoad() {
        showNone()
    }
    
    func show(tracks: [Track]) {
        context = Library.shared.newConcurrentContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy // User is always right
        self.tracks = context.compactConvert(tracks)
        
        view.setFullSizeContent(_contentView)
    }
    
    func showNone() {
        view.setFullSizeContent(_nonePlaceholder)
    }
    
    func suggest(tracks: [Track]) {
        manyTracks = tracks
        
        view.setFullSizeContent(_manyPlaceholder)
    }
    
    @IBAction func save(_ sender: Any) {
        for track in tracks {
            // Don't call the collection method since it auto-saves in the wrong context
            Library.shared.mediaLocation.updateLocation(of: track)
        }
        
        try! context.save()

        for track in tracks {
            track.writeMetadata()
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
    }
    
    @IBAction func showSuggestedTracks(_ sender: Any) {
        show(tracks: manyTracks)
    }
}

class FileTagEditorWindow: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
}
