//
//  Cocoa+IBInspectable.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension NSTableHeaderView {
    var vibrancyView: NSVisualEffectView? {
        // A little hacky but eh
        return superview?.subviews.flatten(by: { $0.subviews }).of(type: NSVisualEffectView.self).first
    }
    
    @IBInspectable var vibrancyMaterial : NSVisualEffectView.Material {
        get { return vibrancyView?.material ?? .appearanceBased }
        set { vibrancyView?.material = newValue }
    }
}
