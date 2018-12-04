//
//  PlayImageView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.12.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class PlayImageView: NSImageView {
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
    var observePlayingToken: NSKeyValueObservation?

    var playImage = NSImage(named: .init("play"))?.tinted(in: .white)
    var pauseImage = NSImage(named: .init("pause"))?.tinted(in: .white)

    func observe(track: Track, playingIn player: Player) {
        observeTrackToken = player.observe(\.playing, options: [.initial, .new]) { _,_  in
            self.showsPlaying = track == player.playing
        }

        observePlayingToken = player.observe(\.playing, options: [.initial, .new]) { _,_  in
            self.isPlaying = player.isPlaying
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if showsPlaying {
            NSColor(white: 0, alpha: 0.3).set()
            dirtyRect.fill()
            
            (isPlaying ? playImage : pauseImage)?.draw(in: NSMakeRect(bounds.minX + bounds.width / 5, bounds.minY + bounds.height / 5, bounds.width / 5 * 3, bounds.height / 5 * 3), from: NSZeroRect, operation: .sourceOver, fraction: 0.5)
        }
    }
    
}
