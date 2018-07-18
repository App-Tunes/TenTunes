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
    var contents: [String] = []
    
    init(title: String, contents: [String]) {
        self.title = title
        self.contents = contents
    }
}

protocol LabelFieldDelegate : NSTokenFieldDelegate {
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [LabelGroup]?
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
    
    var editingString: String {
        return ((objectValue as! NSArray).lastObject) as? String ?? ""
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        let editingString = self.editingString

        guard let delegate = delegate as? LabelFieldDelegate, editingString.count > 0 else {
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
                
                if let delegate = self.delegate, let repObject = self.delegate?.tokenField?(self, representedObjectForEditing: content), let displayString = delegate.tokenField?(self, displayStringForRepresentedObject: repObject) {
                    button.title = displayString
                }
                else {
                    button.title = content
                }
                
                actionStubs.bind(button) { _ in
                    self.autocompletePopover.close()
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
    
    func autocomplete(with: String) {
        stringValue = stringValue[..<(-editingString.count)] + with
        currentEditor()?.moveToEndOfLine(nil)
    }
}
