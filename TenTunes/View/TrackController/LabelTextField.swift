//
//  LabelTextField.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 18.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class LabelGroup {
    let title: String
    var contents: [Any] = []
    
    init(title: String, contents: [Any]) {
        self.title = title
        self.contents = contents
    }
}

protocol LabelFieldDelegate : NSTokenFieldDelegate {
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [LabelGroup]?

    func tokenFieldChangedLabels(_ tokenField: NSTokenField, labels: [Any])
}

class LabelAutocompleteViewController : NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func loadView() {
        view = TagContentView()
        view.translatesAutoresizingMaskIntoConstraints = false
    }
}

class TagContentView : NSView, PopoverFirstResponderStealingSuppression {
    var suppressFirstResponderWhenPopoverShows: Bool { return true }
}

class LabelTextField: NSTokenField {
    var _autocompletePopover: NSPopover?
    
    var actionStubs = ActionStubs()
    var objectValueObservation: NSKeyValueObservation?
    
    var autocompletePopover: NSPopover {
        if _autocompletePopover == nil {
            _autocompletePopover = NSPopover()
            _autocompletePopover!.contentViewController = LabelAutocompleteViewController()
            _autocompletePopover!.animates = true
            _autocompletePopover!.behavior = .transient
            _autocompletePopover!.appearance = window!.appearance
        }
        
        return _autocompletePopover!
    }
    
    @objc dynamic var currentLabels: [Any] {
        get { return (objectValue as! NSArray).filter { !($0 is String) } }
        set { objectValue = newValue as NSArray }
    }
    
    var editingIndex: Int {
        guard var selectedPos = currentEditor()?.selectedRange.location, let array = objectValue as? NSArray else {
            return 0
        }
        
        for (idx, obj) in array.enumerated() {
            if let string = obj as? String {
                selectedPos -= string.count
            }
            else {
                selectedPos -= 1
            }
            
            if selectedPos <= 0 {
                return idx
            }
        }
        
        return array.count - 1
    }
    
    var editingString: String {
        return (objectValue as? NSArray)?[editingIndex] as? String ?? ""
    }
    
    func notifyLabelChange() {
        if let delegate = self.delegate as? LabelFieldDelegate {
            delegate.tokenFieldChangedLabels(self, labels: self.currentLabels)
        }
    }
    
    override func awakeFromNib() {
        objectValueObservation = self.observe(\.objectValue, options: [.new]) { [unowned self] object, change in
            self.notifyLabelChange()
        }
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        let editingString = self.editingString
        
        guard let delegate = delegate as? LabelFieldDelegate, editingString.count > 0 else {
            _autocompletePopover?.close()
            notifyLabelChange()
            return
        }
        
        actionStubs.clear()
        
        // TODO Fix indices
        let groups = delegate.tokenField(self, completionGroupsForSubstring: editingString, indexOfToken: 0, indexOfSelectedItem: UnsafeMutablePointer(bitPattern: 0))
        
        let view = autocompletePopover.contentViewController!.view
        view.removeConstraints(view.constraints)
        view.subviews = [] // Cleanup
        
        autocompletePopover.contentSize = NSMakeSize(frame.size.width, 10 + CGFloat((groups?.count ?? 0) * 50))
        
        for (idx, group) in (groups ?? []).enumerated() {
            let label = NSTextField()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isBordered = false
            label.isSelectable = false
            label.font = NSFont.boldSystemFont(ofSize: 12)
            
            label.stringValue = group.title
            
            view.addSubview(label)
            
            view.addConstraint(NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: CGFloat(5 + idx * 50)))
            view.addConstraint(NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 5))
            
            var prev: NSView? = nil
            for content in group.contents {
                let button = NSButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setButtonType(.momentaryPushIn)
                button.bezelStyle = .rounded
                
                if let delegate = self.delegate, let displayString = delegate.tokenField?(self, displayStringForRepresentedObject: content) {
                    button.title = displayString
                }
                else {
                    fatalError("Not Implemented")
                }
                
                actionStubs.bind(button) { _ in
                    self.autocomplete(with: content)
                }
                
                view.addSubview(button)
                
                view.addConstraint(NSLayoutConstraint(item: button, attribute: .leading, relatedBy: .equal, toItem: prev ?? view, attribute: prev != nil ? .trailing : .leading, multiplier: 1, constant: 5))
                view.addConstraint(NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: label, attribute: .bottom, multiplier: 1, constant: 5))
                
                prev = button
            }
        }
        
        autocompletePopover.show(relativeTo: bounds, of: self, preferredEdge: .maxY)
    }
    
    func autocomplete(with: Any) {
        // Strip away unfinished strings by using currentLabels rather than objectValue
        let idx = editingIndex
        currentLabels.insert(with, at: idx)
        // When we have no strings, location is equal to the number of labels
        currentEditor()?.selectedRange = NSMakeRange(idx + 1, 0)
        self.autocompletePopover.close()
    }
}
