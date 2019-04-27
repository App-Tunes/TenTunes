//
//  VisualizerWindowController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import CoreGraphics

class VisualizerWindowController: NSWindowController {
    var visualizerController: VisualizerViewController!

    override func awakeFromNib() {
        visualizerController = VisualizerViewController.create()
        window!.contentView!.setFullSizeContent(visualizerController.view)
    }
}

// TODO Move to visualizer view
extension VisualizerWindowController : VisualizerWindowDelegate {
    func togglePlay() -> VisualizerWindow.PauseResult? {
        return visualizerController.connection?.pause?()
    }
}
