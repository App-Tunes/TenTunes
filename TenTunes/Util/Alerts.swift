//
//  Alerts.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension NSAlert {
    static func ensure(intent: Bool, action: String, text: String, run: () -> Swift.Void) {
        if !intent {
            confirming(action: action, text: text, run: run)
        }
        else {
            run()
        }
    }
    
    static func confirming(action: String, text: String, run: () -> Swift.Void) {
        let alert = NSAlert()
        alert.messageText = action
        alert.informativeText = text
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            run()
        }
    }
}
