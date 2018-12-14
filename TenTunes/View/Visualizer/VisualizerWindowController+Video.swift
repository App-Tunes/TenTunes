//
//  VisualizerWindowController+Video.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension VisualizerWindowController {
    @IBAction func selectedMode(_ sender: Any) {
        let old = _visualizerView!
        
        switch (sender as! NSPopUpButton).selectedItem!.identifier!.rawValue {
        case "suns":
            _visualizerView = Cloud()
        case "honey":
            _visualizerView = Honey()
        case "darkMatter":
            _visualizerView = DarkMatter()
        default:
            fatalError("Unknown Mode!")
        }

        _visualizerView.delegate = old.delegate
        _visualizerView.colorVariance = old.colorVariance
        _visualizerView.brightness = old.brightness
        _visualizerView.psychedelic = old.psychedelic
        _visualizerView.details = old.details
        
        _visualizerView.startDate = old.startDate
        _visualizerView.distortionRands = old.distortionRands

        _visualizerView.translatesAutoresizingMaskIntoConstraints = false
        window?.contentView?.replaceSubview(old, with: _visualizerView)
        window?.contentView?.addConstraints(NSLayoutConstraint.copyLayout(from: window!.contentView!, for: _visualizerView))
        
        // Re-Setup Output
        selectedRenderingMethod(_renderingMethodSelector)
    }
    
    @IBAction func selectedRenderingMethod(_ sender: Any) {
        let isSyphon = (sender as! NSPopUpButton).selectedItem?.identifier?.rawValue == "syphon"
        
        guard isSyphon != (syphon != nil) else {
            return
        }
        
        _visualizerView.drawMode = .direct // Set in case !isSyphon
        syphon = isSyphon ? Syphon.offer(view: _visualizerView, as: "Visualizer") : nil
        _visualizerView?.updateDisplayLink()
    }
}
