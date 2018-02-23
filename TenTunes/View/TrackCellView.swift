//
//  TrackCellView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class TrackCellView: NSTableCellView {

    @IBOutlet var subtitleTextField: NSTextField?
    @IBOutlet var lengthTextField: NSTextField?
    @IBOutlet var keyTextField: NSTextField?
    @IBOutlet var bpmTextField: NSTextField?
    
    var track: Track?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func awakeFromNib() {
        if let view = self.imageView {
            view.wantsLayer = true
            
            view.layer!.borderWidth = 1.0
            view.layer!.borderColor = NSColor.lightGray.cgColor.copy(alpha: CGFloat(0.333))
            view.layer!.cornerRadius = 3.0
            view.layer!.masksToBounds = true
        }
    }
    
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            self.subtitleTextField?.textColor = backgroundStyle == NSView.BackgroundStyle.light ? NSColor.darkGray : NSColor.lightGray
            self.lengthTextField?.textColor = NSColor.gray
        }
    }
    
    var key: NSAttributedString? {
        didSet {
            self.keyTextField?.attributedStringValue = self.key!
            self.keyTextField?.alignment = NSTextAlignment.right // Need to do this after, cause setting the string resets it
        }
    }
}