//
//  VisualizerWindow.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.12.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol VisualizerWindowDelegate {
    @discardableResult
    func togglePlay() -> VisualizerWindow.PauseResult?
}

class VisualizerWindow: NSWindow {
    enum PauseResult {
        case paused, played
    }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == " " {
            // TODO Show that we pressed with a small visualization
            (delegate as? VisualizerWindowDelegate)?.togglePlay()
            return
        }
        
        super.keyDown(with: event)
    }
}
