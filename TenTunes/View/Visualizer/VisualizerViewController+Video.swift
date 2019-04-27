//
//  VisualizerWindowController+Video.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension VisualizerViewController {
    enum VideoMode: String, Codable {
        case honey = "Honey"
        case darkMatter = "DarkMatter"
    }
    
    @IBAction func selectedMode(_ sender: Any) {
        videoMode = (sender as! NSPopUpButton).selectedItem!.representedObject as! VideoMode
    }
    
    func updateVideoMode() {
        // Just so it's non-optional
        var new: VisualizerView = visualizerView

        switch videoMode {
        case .honey:
            new = Honey()
        case .darkMatter:
            new = DarkMatter()
        }

        new.delegate = self

        if let old = visualizerView {
            new.colorVariance = old.colorVariance
            new.brightness = old.brightness
            new.psychedelic = old.psychedelic
            new.details = old.details
            
            new.startDate = old.startDate
            new.distortionRands = old.distortionRands
        }
        
        visualizerView = new
    }
    
    @IBAction func selectedRenderingMethod(_ sender: Any) {
        let isSyphon = (sender as! NSPopUpButton).selectedItem?.identifier?.rawValue == "syphon"
        
        guard isSyphon != (syphon != nil) else {
            return
        }
        
        visualizerView.drawMode = .direct // Set in case !isSyphon
        syphon = isSyphon ? Syphon.offer(view: visualizerView, as: "Visualizer") : nil
        visualizerView.updateDisplayLink()
    }
}
