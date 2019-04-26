//
//  OptionsStep.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class OptionsStep: NSViewController {
    
    @IBOutlet var _text: NSTextField!
    @IBOutlet var _box: NSBox!
    
    var _options: [OptionStep] = []
    var _actions = ActionStubs()
    
    var text: String {
        get { return _text.stringValue }
        set { _text.stringValue = newValue }
    }
    
    static func create(text: String, options: [OptionStep]) -> OptionsStep {
        let controller = OptionsStep(nibName: .init("OptionsStep"), bundle: .main)
        controller.loadView()
        controller.text = text
        options.forEach(controller.addOption)
        return controller
    }
    
    func addOption(_ option: OptionStep) {
        _options.append(option)
        
        guard let action = option.action else {
            return
        }
        
        option.action = { [unowned self] in
            guard action() else {
                return false
            }
            
            self._options
                .filter { $0 != option }
                .forEach { $0.permanentAnswer = false }
            
            return true
        }
    }
    
    override func viewWillAppear() {
        let container = _box.contentView!
        
        var previous: NSView? = nil
        for option in _options {
            let view = option.view
            view.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(view)
            
            container.addConstraints([
                NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: previous ?? container, attribute: previous == nil ? .leading : .trailing, multiplier: 1, constant: 8),
                NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1, constant: 8),
                NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1, constant: -8),
            ])
            
            if let previous = previous {
                container.addConstraint(
                    NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: previous, attribute: .width, multiplier: 1, constant: 0)
                )
            }
            
            previous = view
        }
        
        if let previous = previous {
            container.addConstraint(
                NSLayoutConstraint(item: previous, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1, constant: -8)
            )
        }
    }    
}
