//
//  Alerts.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension NSAlert {
    static func informational(title: String, text: String, confirm: String? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    static func tutorial(topic: String, text: String) {
        informational(title: topic, text: text, confirm: "Got it!")
    }
    
    static func ensure(intent: Bool, action: String, text: String) -> Bool {
        guard intent else {
            return confirm(action: action, text: text)
        }
        
        return true
    }
    
    static func confirm(action: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = action
        alert.informativeText = text
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        let response = alert.runModal()
        
        return response == .alertFirstButtonReturn
    }
    
    static func choose(title: String, text: String, actions: [String]) -> NSApplication.ModalResponse {
        guard actions.count < 4 else {
            fatalError("Action count > 3")
        }
        
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        
        for action in actions {
            alert.addButton(withTitle: action)
        }
        
        return alert.runModal()
    }
}

extension NSApplication {
    func terminate(withErrorTitle title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
        terminate(self)
    }
}
