//
//  DragHighlightView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 18.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class DragHighlightView: NSView {
    var isReceivingDrag = false {
        didSet { needsDisplay = true }
    }
    
    var delegate: NSDraggingDestination?
    
    static func add(to view: NSView) -> DragHighlightView {
        let highlight = DragHighlightView()
        highlight.translatesAutoresizingMaskIntoConstraints = false
        highlight.delegate = view
        highlight.frame = view.bounds
        
        view.addSubview(highlight, positioned: .above, relativeTo: nil)
        view.addConstraints(NSLayoutConstraint.copyLayout(from: view, for: highlight))
        return highlight
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if isReceivingDrag {
            NSColor.selectedControlColor.set()
            
            let path = NSBezierPath(rect:bounds)
            path.lineWidth = 4
            path.stroke()
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return delegate?.performDragOperation?(sender) ?? false
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        delegate?.concludeDragOperation?(sender)
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        delegate?.draggingEnded?(sender)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return delegate?.draggingEntered?(sender) ?? []
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        delegate?.draggingExited?(sender)
    }
}
