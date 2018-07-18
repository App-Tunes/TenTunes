//
//  TTWindow.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 18.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol PopoverFirstResponderStealingSuppression {
    var suppressFirstResponderWhenPopoverShows: Bool { get }
}

class TTWindow: NSWindow {
    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        if responder != firstResponder, let responderView = responder as? NSView {
            // Prevent popover content view from forcing our current first responder to resign
            
            let newFirstResponderWindow = responderView.window!
            var currentFirstResponderWindow: NSWindow? = nil
            
            let currentFirstResponder = firstResponder
            if let currentFirstResponder = currentFirstResponder as? NSWindow {
                currentFirstResponderWindow = currentFirstResponder
            }
            else if let currentFirstResponder = currentFirstResponder as? NSView {
                currentFirstResponderWindow = currentFirstResponder.window
            }
            
            // Prevent some view in popover from stealing our first responder, but allow the user to explicitly activate it with a click on the popover.
            // Note that the current first responder may be in a child window, if it's a control in the "thick titlebar" area and we're currently full-screen.
            
            if newFirstResponderWindow != self, newFirstResponderWindow != currentFirstResponderWindow, currentEvent?.window != newFirstResponderWindow {
                
                var currentView: NSView? = responderView
                while currentView != nil {
                    if let currentView = currentView as? PopoverFirstResponderStealingSuppression, currentView.suppressFirstResponderWhenPopoverShows {
                        return false
                    }
                    
                    currentView = currentView?.superview
                }
            }
        }
        
        return super.makeFirstResponder(responder)
    }
}
