//
//  VisualizerWindowController+Video.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension VisualizerWindowController {
    @IBAction func selectedRenderingMethod(_ sender: Any) {
        let isSyphon = (sender as! NSPopUpButton).selectedItem?.identifier?.rawValue == "syphon"
        
        guard isSyphon != (syphon != nil) else {
            return
        }
        
        _visualizerView.overrideTextureID = -1 // Set in case !isSyphon
        syphon = isSyphon ? Syphon.offer(view: _visualizerView, as: "Visualizer") : nil
        _visualizerView?.updateDisplayLink()
    }
}
