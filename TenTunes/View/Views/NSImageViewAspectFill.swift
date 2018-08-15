//
//  NSImageViewAspectFill.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.04.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

open class NSImageViewAspectFill : NSView {
    open var image: NSImage? {
        didSet {
            needsDisplay = true
        }
    }
    
    var aspectFill = false
    
    private func saveGState(drawStuff: (CGContext) -> ()) -> () {
        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState ()
            drawStuff(context)
            context.restoreGState ()
        }
    }

    open override func draw(_ dirtyRect: NSRect) {
        let ctx = NSGraphicsContext.current!.cgContext
        
        if let image = image {
            saveGState { ctx in
                guard aspectFill else {
                    let blurred = image.resized(w: frame.size.width, h: frame.size.height)
                        .blurred(radius: 50)
                    blurred.draw(in: frame, from: NSZeroRect, operation: .sourceOver, fraction: 1)
                    
                    return
                }
                
                let diff = frame.size.width / frame.size.height
                let blurAmount = Double(min(20, max(image.size.width, image.size.height) / 8))
                let blurred = image.blurred(radius: blurAmount)
                
                blurred.draw(in: frame, from: NSMakeRect(0, blurred.size.height / 2 - blurred.size.height / diff / 2, blurred.size.width, blurred.size.height / diff), operation: .sourceOver, fraction: 1)
            }
        }
        

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: [CGColor.clear, CGColor.black] as CFArray, locations: [0.8, 1])
        let center = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        let radius = max(bounds.width / 2.0, bounds.height / 2.0)
        ctx.drawRadialGradient(gradient!, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: radius, options: CGGradientDrawingOptions(rawValue: 0))
    }
}
