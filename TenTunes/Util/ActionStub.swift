//
//  ActionStub.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.06.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class ActionStub {
    static func bind(_ button: NSControl, action: @escaping (Any) -> Swift.Void) {
        button.target = ActionStub(action)
        button.action = #selector(run)
    }
    
    static func bind(_ button: NSMenuItem, action: @escaping (Any) -> Swift.Void) {
        button.target = ActionStub(action)
        button.action = #selector(run)
    }
    
    let action: (Any) -> Swift.Void
    
    init(_ action: @escaping (Any) -> Swift.Void) {
        self.action = action
    }
    
    @IBAction func run(_ sender: Any) {
        action(sender)
    }
}
