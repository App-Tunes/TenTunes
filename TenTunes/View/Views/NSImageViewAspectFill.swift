//
//  NSImageViewAspectFill.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.04.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

open class NSImageViewAspectFill : NSView {
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer = CALayer()
        layer!.contentsGravity = kCAGravityResizeAspectFill
    }
    
    open var image: NSImage? {
        didSet {
            layer!.contents = image
        }
    }
}
