//
//  CompletionStep.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class CompletionStep: NSViewController {
    
    @IBOutlet var _text: NSTextField!
    @IBOutlet var _button: NSButton!
    
    var completion: (() -> Void)?
    
    var text: String {
        get { return _text.stringValue }
        set { _text.stringValue = newValue }
    }
    
    var buttonText: String {
        get { return _button.title }
        set { _button.title = newValue }
    }
    
    static func create(text: String, buttonText: String, completion: @escaping () -> Void) -> CompletionStep {
        let controller = CompletionStep(nibName: .init("CompletionStep"), bundle: .main)
        controller.loadView()
        controller.text = text
        controller.buttonText = buttonText
        controller.completion = completion
        return controller
    }
    
    @IBAction func action(_ sender: Any) {
        view.window?.close()
        completion?()
    }
}
