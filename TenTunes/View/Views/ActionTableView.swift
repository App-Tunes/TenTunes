
//
//  ActionTableView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class ActionTableView: NSTableView {

    @objc
    var enterAction: Selector?
    
    override func keyDown(with event: NSEvent) {
        guard !(Keycodes.enterKey.matches(event: event) || Keycodes.returnKey.matches(event: event)) else {
            if let enterAction = enterAction {
                target?.performSelector(onMainThread: enterAction, with: event, waitUntilDone: false)
            }
            
            return
        }
        
        super.keyDown(with: event)
    }
}
