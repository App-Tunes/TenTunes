//
//  PlayImageView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.12.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class PlayImageView: NSButton {
    var showsPlaying: Bool = false {
        didSet {
            if showsPlaying != oldValue {
                setNeedsDisplay()
            }
        }
    }
    var isPlaying: Bool = false {
        didSet {
            if showsPlaying { setNeedsDisplay() }
        }
    }

    var observeTrackToken: NSKeyValueObservation?

    var playImage = NSImage(named: .init("play"))?.tinted(in: .white)
    var playingImage = NSImage(named: .init("music"))?.tinted(in: .white)
    
    var isHovering = false {
        didSet {
            setNeedsDisplay()
        }
    }

    func observe(track: Track, playingIn player: Player) {
        observeTrackToken = player.observe(\.playing, options: [.initial, .new]) { [unowned self] player, _  in
            self.showsPlaying = track == player.playing
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) { isHovering = true }
    
    override func mouseExited(with event: NSEvent) { isHovering = false }
    
    var symbolRect: NSRect {
        return NSMakeRect(bounds.minX + bounds.width / 5, bounds.minY + bounds.height / 5, bounds.width / 5 * 3, bounds.height / 5 * 3)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard action != nil else {
            return
        }
        
        if showsPlaying || isHovering {
            NSColor(white: 0, alpha: 0.5).set()
            dirtyRect.fill()
        }
        
        let transform = NSAffineTransform()
        transform.translateX(by: 0, yBy: bounds.height)
        transform.scaleX(by: 1, yBy: -1)
        transform.concat()
        
        if showsPlaying {
            playingImage?.draw(in: symbolRect, from: NSZeroRect, operation: .sourceOver, fraction: 0.7)
        }
        else if isHovering {
            playImage?.draw(in: symbolRect, from: NSZeroRect, operation: .sourceOver, fraction: 0.7)
        }
    }
}
