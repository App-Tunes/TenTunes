//
//  Alerts.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension NSAlert {
    static func informational(title: String, text: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    static func ensure(intent: Bool, action: String, text: String, run: () -> Swift.Void) -> Bool {
        guard intent else {
            return confirm(action: action, text: text)
        }
        
        return true
    }
    
    static func ensure(intent: Bool, action: String, text: String) -> Bool {
        return confirm(action: action, text: text)
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
}
