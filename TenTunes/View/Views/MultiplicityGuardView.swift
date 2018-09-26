//
//  MultiplicityGuardView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol MultiplicityGuardDelegate {
    func multiplicityGuard(_ view: MultiplicityGuardView, show elements: [Any]) -> MultiplicityGuardView.ShowAction
}

class MultiplicityGuardView: NSView {
    enum ShowAction {
        case show
        case error(text: String)
    }

    typealias Element = Any
    
    var contentView: NSView?
    var delegate: MultiplicityGuardDelegate?
    
    var deferredElements: [Element]? = nil

    @IBOutlet var _manyPlaceholder: NSView?
    @IBOutlet var _manyTextField: NSTextField!
    @IBOutlet var _confirmShowMany: NSButton!
    
    @IBOutlet var _errorPlaceholder: NSView?
    @IBOutlet var _errorTextField: NSTextField?
    
    var errorSelectionEmpty = "No Items Selected"
    
    var bigSelectionCount = 2
    var warnSelectionBig: String {
        get { return _manyTextField.stringValue }
        set { _manyTextField.stringValue = newValue }
    }
    var confirmShowView: String {
        get { return _confirmShowMany.title }
        set { _confirmShowMany.title = newValue }
    }

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
        showError(text: errorSelectionEmpty)
    }
    
    func present(elements: [Element]) {
        guard !isHidden else {
            deferredElements = elements
            showError(text: "View Hidden")
            return
        }
        deferredElements = nil
        
        if elements.count == 0 {
            showError(text: errorSelectionEmpty)
        }
        else if elements.count < bigSelectionCount {
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
        switch delegate?.multiplicityGuard(self, show: elements) {
        case .error(let text)?:
            showError(text: text)
            return
        default:
            break
        }
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
