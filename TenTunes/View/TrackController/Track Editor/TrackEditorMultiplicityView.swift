//
//  TrackEditor+Pasteboard.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class TrackEditorMultiplicityView : MultiplicityGuardView {    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // This setup allows us to receive drags first
        dragHighlightView.registerForDraggedTypes(TrackPromise.pasteboardTypes)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard TrackPromise.inside(pasteboard: sender.draggingPasteboard, for: Library.shared) != nil else {
            return []
        }

        dragHighlightView.isReceivingDrag = true
        return .generic
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        dragHighlightView.isReceivingDrag = false
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        dragHighlightView.isReceivingDrag = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let promises = TrackPromise.inside(pasteboard: sender.draggingPasteboard, for: Library.shared) else {
            return false
        }
        
        let tracks = promises.compactMap { $0.fire() }

        show(elements: tracks)
        
        return true
    }
}
