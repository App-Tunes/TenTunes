//
//  TrackControllerView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class TrackControllerView: NSView {

    override func viewDidMoveToWindow() {
        // NSPanel Shenanigans
        guard let frameView = window?.contentView?.superview else {
            return
        }
        
//        let backgroundView = NSView(frame: frameView.bounds)
//        backgroundView.wantsLayer = true
//        backgroundView.layer?.backgroundColor = .black // colour of your choice
//        backgroundView.autoresizingMask = [.width, .height]
//
//        frameView.addSubview(backgroundView, positioned: .below, relativeTo: frameView)
    }
}
