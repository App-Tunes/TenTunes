//
//  MultiplicityGuardView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol MultiplicityGuardDelegate : class {
    func multiplicityGuard(_ view: MultiplicityGuardView, show elements: [Any]) -> MultiplicityGuardView.ShowAction
}

class MultiplicityGuardView: NSView {
    enum ShowAction {
        case show
        case error(text: String)
    }

    typealias Element = Any
    
    var dragHighlightView: DragHighlightView!

    var contentView: NSView?
    weak var delegate: MultiplicityGuardDelegate?
    
    var deferredElements: [Element]? = nil
    
    var currentView: NSView? {
        didSet {
            guard oldValue != currentView else {
                return
            }
            
            currentView?.frame = bounds
            removeSubview(oldValue, andAdd: currentView, order: .below)
            if let currentView = currentView {
                addConstraints(NSLayoutConstraint.copyLayout(from: self, for: currentView))
            }
        }
    }

    @IBOutlet var _manyPlaceholder: NSView?
    @IBOutlet var _manyTextField: NSTextField!
    @IBOutlet var _confirmShowMany: NSButton!
    
    @IBOutlet var _errorPlaceholder: NSView?
    @IBOutlet var _errorTextField: NSTextField!
    
    @IBInspectable
    var errorSelectionEmpty: String = "No Items Selected"
    
    @IBInspectable
    var bigSelectionCount: Int = 2
    @IBInspectable
    var warnSelectionBig: String {
        get { return _manyTextField.stringValue }
        set { _manyTextField.stringValue = newValue }
    }
    @IBInspectable
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
        _manyPlaceholder = NSView()
        _manyPlaceholder?.translatesAutoresizingMaskIntoConstraints = false
        
        _manyTextField = NSTextField(string: "Many Items Selected")
        _manyTextField.translatesAutoresizingMaskIntoConstraints = false
        _manyTextField.isSelectable = false
        _manyTextField.drawsBackground = false
        _manyTextField.isBordered = false
        _manyTextField.textColor = .secondaryLabelColor
        _manyTextField.setContentCompressionResistancePriority(.init(50), for: .horizontal)
        
        _confirmShowMany = NSButton(title: "Show", target: self, action: #selector(showSuggested))
        _confirmShowMany.translatesAutoresizingMaskIntoConstraints = false
        
        _manyPlaceholder!.addSubview(_manyTextField)
        _manyPlaceholder!.addSubview(_confirmShowMany)
        
        // Center
        _manyPlaceholder!.addConstraints(NSLayoutConstraint.center(in: _manyPlaceholder!, for: _confirmShowMany!))
        _manyPlaceholder?.addConstraint(NSLayoutConstraint(item: _manyTextField!, attribute: .bottom, relatedBy: .equal, toItem: _confirmShowMany, attribute: .top, multiplier: 1, constant: -10))
        _manyPlaceholder?.addConstraint(NSLayoutConstraint(item: _manyTextField!, attribute: .centerX, relatedBy: .equal, toItem: _confirmShowMany, attribute: .centerX, multiplier: 1, constant: 0))
        
        // Don't squish
        _manyPlaceholder?.addConstraint(NSLayoutConstraint(item: _manyTextField!, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: _manyPlaceholder!, attribute: .leading, multiplier: 1, constant: 0))
        _manyPlaceholder?.addConstraint(NSLayoutConstraint(item: _confirmShowMany!, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: _manyPlaceholder!, attribute: .leading, multiplier: 1, constant: 0))
        
        //
        
        _errorPlaceholder = NSView()
        _errorPlaceholder?.translatesAutoresizingMaskIntoConstraints = false
        
        _errorTextField = NSTextField(string: "No Items Selected")
        _errorTextField.translatesAutoresizingMaskIntoConstraints = false
        _errorTextField.isSelectable = false
        _errorTextField.drawsBackground = false
        _errorTextField.isBordered = false
        _errorTextField.textColor = .secondaryLabelColor
        _errorTextField.setContentCompressionResistancePriority(.init(50), for: .horizontal)
        
        _errorPlaceholder!.addSubview(_errorTextField)
        _errorPlaceholder!.addConstraints(NSLayoutConstraint.center(in: _errorPlaceholder!, for: _errorTextField!))
        _errorPlaceholder?.addConstraint(NSLayoutConstraint(item: _errorTextField!, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: _errorPlaceholder!, attribute: .leading, multiplier: 1, constant: 0))
        
        //

        dragHighlightView = DragHighlightView.add(to: self)
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
    
    func show(elements: [Element]) {
        guard !isHidden else {
            deferredElements = elements
            showError(text: "View Hidden")
            return
        }
        deferredElements = nil

        switch delegate?.multiplicityGuard(self, show: elements) {
        case .error(let text)?:
            showError(text: text)
            return
        default:
            break
        }
        currentView = contentView
    }
    
    func showError(text: String) {
        _errorTextField?.stringValue = text
        currentView = _errorPlaceholder
    }
    
    func suggest(elements: [Element]) {
        deferredElements = elements
        
        currentView = _manyPlaceholder
    }
    
    @IBAction func showSuggested(_ sender: Any) {
        deferredElements.map(show)
        deferredElements = nil
    }
}
