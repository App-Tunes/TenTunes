//
//  CompletionStep.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class ConfirmStep: NSViewController {
    enum Mode {
        case next, complete
    }
    
    @IBOutlet var _text: NSTextField!
    @IBOutlet var _button: NSButton!
    
    var mode: Mode = .next
    var action: (() -> Void)?
    
    var text: String {
        get { return _text.stringValue }
        set { _text.stringValue = newValue }
    }
    
    var buttonText: String {
        get { return _button.title }
        set { _button.title = newValue }
    }
    
    static func create(text: String, buttonText: String, mode: Mode = .next, action: (() -> Void)? = nil) -> ConfirmStep {
        let controller = ConfirmStep(nibName: .init("ConfirmStep"), bundle: .main)
        controller.loadView()
        controller.text = text
        controller.buttonText = buttonText
        controller.mode = mode
        controller.action = action
        return controller
    }
    
    @IBAction func action(_ sender: Any) {
        switch mode {
        case .next:
            WorkflowWindowController.next(view)
        case .complete:
            view.window?.close()
        }
        
        action?()
    }
}
