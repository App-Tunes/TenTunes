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

    var playImage = NSImage(named: "play")?.tinted(in: .white)
    var playingImage = NSImage(named: "music")?.tinted(in: .white)
    
    var hoverTrackingArea: NSTrackingArea? {
        didSet {
            oldValue.map(removeTrackingArea)
            hoverTrackingArea.map(addTrackingArea)
        }
    }
    
    var isHovering = false {
        didSet {
            if isHovering != oldValue {
                setNeedsDisplay()
            }
        }
    }

    func observe(track: Track, playingIn player: Player) {
        observeTrackToken?.invalidate()
        observeTrackToken = player.observe(\.playing, options: [.initial, .new]) { [unowned self] player, _  in
            self.showsPlaying = track == player.playing
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        hoverTrackingArea = NSTrackingArea(rect: bounds, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
        
        if (!bounds.contains(convert(NSEvent.mouseLocation, from: nil))) {
            isHovering = false
        }
    }
    
    override func mouseEntered(with event: NSEvent) { isHovering = true }
    
    override func mouseExited(with event: NSEvent) { isHovering = false }
    
    var symbolRect: NSRect {
        return NSMakeRect(bounds.minX + bounds.width / 5, bounds.minY + bounds.height / 5, bounds.width / 5 * 3, bounds.height / 5 * 3)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
                
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
