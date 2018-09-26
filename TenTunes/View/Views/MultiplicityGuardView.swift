//
//  MultiplicityGuardView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class MultiplicityGuardView: NSView {
    typealias Element = Any
    
    var contentView: NSView?
    var updater: (([Element]) -> Void)? = nil
    
    var deferredElements: [Element]? = nil

    @IBOutlet var _manyPlaceholder: NSView?
    @IBOutlet var _errorPlaceholder: NSView?
    @IBOutlet var _errorTextField: NSTextField?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        loadDefaultPlaceholders()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        loadDefaultPlaceholders()
    }
    
    func loadDefaultPlaceholders() {
        loadNib()
    }
    
    override func viewDidUnhide() {
        if let deferredElements = deferredElements {
            present(elements: deferredElements) // Try presenting again
        }
    }
    
    override func awakeFromNib() {
        showError(text: "No Tracks Selected")
    }
    
    func present(elements: [Element]) {
        guard !isHidden else {
            deferredElements = elements
            showError(text: "View Hidden")
            return
        }
        deferredElements = nil
        
        if elements.count == 0 {
            showError(text: "No Tracks Selected")
        }
        else if elements.count < 2 {
            show(elements: elements)
        }
        else {
            suggest(elements: elements)
        }
    }
    
    func show(view: NSView?) {
        setFullSizeContent(view)
    }
    
    func show(elements: [Element]) {
        updater?(elements)
        show(view: contentView)
    }
    
    func showError(text: String) {
        _errorTextField?.stringValue = text
        show(view: _errorPlaceholder)
    }
    
    func suggest(elements: [Element]) {
        deferredElements = elements
        
        show(view: _manyPlaceholder)
    }
    
    @IBAction func showSuggested(_ sender: Any) {
        deferredElements ?=> show
        deferredElements = nil
    }
}
