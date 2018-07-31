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
    let maxButtonsPerRow = 10
    
    var _autocompletePopover: NSPopover?
    
    var actionStubs = ActionStubs()
    var objectValueObservation: NSKeyValueObservation?
    
    fileprivate var rows: [Row] = []
    
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
        get { return (objectValue as? NSArray)?.filter { !($0 is String) } ?? [] }
        set { objectValue = newValue as NSArray }
    }
    
    func reloadLabels() {
        let value = currentLabels
        objectValue = value
    }
    
    fileprivate class Row {
        var buttons: [NSButton] = []
        let view: NSView = NSView()
        let title: NSTextField = NSTextField()
    }
    
    fileprivate func row(at: Int) -> Row {
        while rows.count <= at {
            var prev: NSView? = nil
            let row = Row()
            row.view.translatesAutoresizingMaskIntoConstraints = false

            row.view.addConstraint(NSLayoutConstraint(item: row.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 45))

            row.title.translatesAutoresizingMaskIntoConstraints = false
            row.title.isBordered = false
            row.title.isSelectable = false
            row.title.font = NSFont.boldSystemFont(ofSize: 12)
            
            row.view.addSubview(row.title)

            row.view.addConstraint(NSLayoutConstraint(item: row.title, attribute: .top, relatedBy: .equal, toItem: row.view, attribute: .top, multiplier: 1, constant: 0))
            row.view.addConstraint(NSLayoutConstraint(item: row.title, attribute: .leading, relatedBy: .equal, toItem: row.view, attribute: .leading, multiplier: 1, constant: 5))

            for _ in 0 ..< maxButtonsPerRow {
                let button = NSButton()
                button.translatesAutoresizingMaskIntoConstraints = false
                button.setButtonType(.momentaryPushIn)
                button.bezelStyle = .rounded

                row.view.addSubview(button)
                
                row.view.addConstraint(NSLayoutConstraint(item: button, attribute: .leading, relatedBy: .equal, toItem: prev ?? row.view, attribute: prev != nil ? .trailing : .leading, multiplier: 1, constant: 5))
                row.view.addConstraint(NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: row.title, attribute: .bottom, multiplier: 1, constant: 5))
                
                prev = button
                row.buttons.append(button)
            }
            
            let view = autocompletePopover.contentViewController!.view

            view.addSubview(row.view)
            
            view.addConstraint(NSLayoutConstraint(item: row.view, attribute: .top, relatedBy: .equal, toItem: rows.last?.view ?? view, attribute: rows.count > 0 ? .bottom : .top, multiplier: 1, constant: 5))
            view.addConstraint(NSLayoutConstraint(item: row.view, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: row.view, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0))
            
            rows.append(row)
        }
        
        return rows[at]
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
        guard let array = objectValue as? NSArray, array.count > 0 else {
            return ""
        }
        
        return array[editingIndex] as? String ?? ""
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
        let groups = delegate.tokenField(self, completionGroupsForSubstring: editingString, indexOfToken: 0, indexOfSelectedItem: UnsafeMutablePointer(bitPattern: 0))?.filter { $0.contents.count > 0 } ?? []
        
        autocompletePopover.contentSize = NSMakeSize(frame.size.width, 10 + CGFloat(groups.count * 50))
        
        for (idx, (group, _)) in longZip(groups, rows).enumerated() {
            let row = self.row(at: idx)
            
            guard let group = group else {
                row.view.isHidden = true
                continue
            }

            row.view.isHidden = false
            row.title.stringValue = group.title
            
            for (content, _button) in longZip(group.contents.prefix(maxButtonsPerRow), row.buttons) {
                guard let content = content, let button = _button else {
                    _button!.isHidden = true
                    continue
                }
                
                button.isHidden = false
                if let delegate = self.delegate, let displayString = delegate.tokenField?(self, displayStringForRepresentedObject: content) {
                    if button.title != displayString {
                        button.title = displayString
                    }
                }
                else {
                    fatalError("Not Implemented")
                }
                
                actionStubs.bind(button) { _ in
                    self.autocomplete(with: content)
                }
            }
        }
        
        autocompletePopover.show(relativeTo: bounds, of: self, preferredEdge: .maxY)
    }
    
    func autocomplete(with: Any?) {
        let idx = editingIndex
        if let with = with {
            // Strip away unfinished strings by using currentLabels rather than objectValue
            currentLabels.insert(with, at: idx)
        }
        else {
            let labels = currentLabels
            currentLabels = labels
        }
        // When we have no strings, location is equal to the number of labels
        currentEditor()?.selectedRange = NSMakeRange(idx + 1, 0)
        
        self.autocompletePopover.close()
    }
}
