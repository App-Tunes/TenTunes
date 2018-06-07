//
//  ActionStub.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.06.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class ActionStubs {
    var stubs: [ActionStub] = []
    
    func clear() {
        stubs = []
    }
    
    func bind(_ button: NSControl, action: @escaping (Any) -> Swift.Void) {
        let stub = ActionStub(action)
        button.target = stub
        button.action = #selector(stub.run)
        stubs.append(stub)
    }
    
    func bind(_ button: NSMenuItem, action: @escaping (Any) -> Swift.Void) {
        let stub = ActionStub(action)
        button.target = stub
        button.action = #selector(stub.run)
        stubs.append(stub)
    }
}

class ActionStub {
    let action: (Any) -> Swift.Void
    
    init(_ action: @escaping (Any) -> Swift.Void) {
        self.action = action
    }
    
    @IBAction func run(_ sender: Any) {
        action(sender)
    }
}
