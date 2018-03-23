//
//  EnterReturningTextField.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class EnterReturningTextField: NSTextField {
    override func keyUp(with event: NSEvent) {
        if Keycodes.enterKey.matches(event: event) || Keycodes.returnKey.matches(event: event) {
            DispatchQueue.main.async{
                self.window?.makeFirstResponder(self.superview!)
            }
        }
        else {
            super.keyDown(with: event)
        }
    }
}
