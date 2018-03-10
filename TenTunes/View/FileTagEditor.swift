//
//  FileTagEditor.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class FileTagEditor: NSWindowController {

    @IBOutlet var _okButton: NSButton!
    @IBOutlet var _cancelButton: NSButton!
    
    @IBOutlet var _title: NSTextField!
    @IBOutlet var _artist: NSTextField!
    @IBOutlet var _album: NSTextField!
    @IBOutlet var _genre: NSTextField!
    @IBOutlet var _bpm: NSTextField!
    @IBOutlet var _key: NSTextField!

    @IBOutlet var _imageView: NSImageView!
    
    var tracks: [Track] = [] {
        didSet {
            guard tracks.count == 1 else {
                return
            }
            let track = tracks.first!
            
            _title.stringValue = track.title ?? ""
            _artist.stringValue = track.author ?? ""
            _album.stringValue = track.album ?? ""
            _genre.stringValue = track.genre ?? ""
            _bpm.stringValue = (track.bpm ?=> String.init) ?? ""
            _key.stringValue = track.key?.write ?? ""
            _imageView.image = track.artwork
        }
    }
    
    
    convenience init() {
        self.init(windowNibName: .init("FileTagEditor"))
        window!.level = .floating
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    @IBAction func save(_ sender: Any) {
        window?.close()
    }
    
    @IBAction func cancel(_ sender: Any) {
        window?.close()
    }
}
