//
//  OptionStep.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class OptionStep: NSViewController {
    @IBOutlet var _text: NSTextField!
    @IBOutlet var _image: NSImageView!
    
    var trackingArea: NSTrackingArea?
    
    var permanentAnswer: Bool? = nil {
        didSet { setHovered(false) }
    }

    var text: String {
        get { return _text.stringValue }
        set { _text.stringValue = newValue }
    }
    
    var image: NSImage? {
        get { return _image.image }
        set { _image.image = newValue }
    }
    
    var isEnabled: Bool { return action != nil }
    
    var action: (() -> Bool)?
    
    static func create(text: String, image: NSImage, action: (() -> Bool)?) -> OptionStep {
        let step = OptionStep()
        step.loadView()
        
        step.text = text
        step.image = image
        step.action = action
        
        return step
    }
    
    override func viewDidAppear() {
        view.wantsLayer = true
        
        view.layer!.cornerRadius = 8
        view.layer!.borderColor = NSColor.gray.cgColor
        setHovered(false)

        trackingArea ?=> view.removeTrackingArea
        trackingArea = .init(rect: view.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self)
        view.addTrackingArea(trackingArea!)
    }
    
    @IBAction func onAction(_ sender: Any) {
        guard permanentAnswer == nil else {
            print("Attempted to act after final answer!")
            return
        }
        
        guard action?() ?? false else {
            return
        }
        
        permanentAnswer = true
        WorkflowWindowController.next(view)
    }
    
    override func mouseUp(with event: NSEvent) {
        onAction(self)
    }
    
    func setColor(_ color: NSColor) {
        if #available(OSX 10.14, *) {
            _image.contentTintColor = color
        }
        _text.textColor = color
    }
    
    func setHovered(_ hovered: Bool) {
        let status = permanentAnswer ?? (isEnabled && hovered)
        
        let background: NSColor = status ? .lightGray : .clear
        view.layer!.backgroundColor = background.cgColor
        view.layer!.borderWidth = status ? 2 : 0
        
        setColor(status ? .labelColor : .secondaryLabelColor)
    }
    
    override func mouseEntered(with event: NSEvent) {
        setHovered(true)
    }
    
    override func mouseExited(with event: NSEvent) {
        setHovered(false)
    }
}
