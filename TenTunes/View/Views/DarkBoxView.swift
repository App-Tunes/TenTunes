//
//  DarkBoxView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 05.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class DarkBoxView: NSView {
    @IBInspectable
    var backgroundAlpha: CGFloat = 0.3 {
        didSet { initDarkLayer() }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        initDarkLayer()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        backgroundAlpha = CGFloat(decoder.decodeDouble(forKey: "backgroundAlpha"))
        
        initDarkLayer()
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        
        aCoder.encode(Double(backgroundAlpha), forKey: "backgroundAlpha")
    }
    
    func initDarkLayer() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            NSColor(white: 0.18, alpha: backgroundAlpha).cgColor,
            NSColor(white: 0.12, alpha: backgroundAlpha).cgColor,
            NSColor(white: 0.08, alpha: backgroundAlpha).cgColor,
        ]
        gradient.locations = [ NSNumber(value: 0), NSNumber(value: 0.2), NSNumber(value: 1) ]
        gradient.cornerRadius = 5
        
        wantsLayer = true
        layer = gradient
    }
}
