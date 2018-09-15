//
//  TTTokenField.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 18.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol TTTokenFieldDelegate : NSTokenFieldDelegate {
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [TTTokenField.TokenGroup]?
    
    func tokenField(_ tokenField: NSTokenField, changedTokens tokens: [Any])
}

class TTTokenField: NSTokenField {
    let maxButtonsPerRow = 5
    
    var _autocompletePopover: NSPopover?
    
    var actionStubs = ActionStubs()
    var objectValueObservation: NSKeyValueObservation?
    
    fileprivate var rows: [Row] = []
    
    var autocompletePopover: NSPopover {
        if _autocompletePopover == nil {
            _autocompletePopover = NSPopover()
            _autocompletePopover!.contentViewController = AutocompleteViewController()
            _autocompletePopover!.animates = true
            _autocompletePopover!.behavior = .transient
            _autocompletePopover!.appearance = window!.appearance
        }
        
        return _autocompletePopover!
    }
    
    @objc dynamic var tokens: [Any] {
        get { return (objectValue as? NSArray)?.filter { !($0 is String) } ?? [] }
        set { objectValue = newValue as NSArray }
    }
    
    func reloadTokens() {
        let value = tokens
        tokens = value
    }
    
    fileprivate class Row {
        var buttons: [NSButton] = []
        let view: NSView = NSView()
        let title: NSTextField = NSTextField()
        let ellipsis: NSTextField = NSTextField(string: "...")
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
            
            if let prev = prev {
                row.ellipsis.isEditable = false
                row.ellipsis.isBordered = false
                row.ellipsis.translatesAutoresizingMaskIntoConstraints = false

                row.view.addSubview(row.ellipsis)
                row.view.addConstraint(NSLayoutConstraint(item: row.ellipsis, attribute: .leading, relatedBy: .equal, toItem: prev, attribute: .trailing, multiplier: 1, constant: 5))
                row.view.addConstraint(NSLayoutConstraint(item: row.ellipsis, attribute: .top, relatedBy: .equal, toItem: row.title, attribute: .bottom, multiplier: 1, constant: 5))
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
        guard var selectedPos = currentEditor()?.selectedRange.location, let array = objectValue as? NSArray, array.count > 0 else {
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
    
    func notifyTokenChange() {
        if let delegate = self.delegate as? TTTokenFieldDelegate {
            delegate.tokenField(self, changedTokens: self.tokens)
        }
    }
    
    override func awakeFromNib() {
        objectValueObservation = self.observe(\.objectValue, options: [.new]) { [unowned self] object, change in
            self.notifyTokenChange()
        }
    }
    
    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        
        let editingString = self.editingString
        
        guard let delegate = delegate as? TTTokenFieldDelegate, editingString.count > 0 else {
            _autocompletePopover?.close()
            notifyTokenChange()
            return
        }
        
        actionStubs.clear()
        
        // TODO Fix indices
        let groups = delegate.tokenField(self, completionGroupsForSubstring: editingString, indexOfToken: 0, indexOfSelectedItem: UnsafeMutablePointer(bitPattern: 0))?.filter { $0.contents.count > 0 } ?? []
        
        guard groups.count > 0 else {
            _autocompletePopover?.close()
            return
        }
        
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
            
            row.ellipsis.isHidden = group.contents.count <= maxButtonsPerRow
        }
        
        autocompletePopover.show(relativeTo: bounds, of: self, preferredEdge: .maxY)
    }
    
    func autocomplete(with: Any?) {
        let idx = editingIndex
        if let with = with {
            // Strip away unfinished strings by using 'tokens' rather than objectValue
            tokens.insert(with, at: idx)
        }
        else {
            // Again, strip tokens
            reloadTokens()
        }
        // When we have no strings, location is equal to the number of tokens
        currentEditor()?.selectedRange = NSMakeRange(idx + 1, 0)
        
        self.autocompletePopover.close()
    }
}

extension TTTokenField {
    class TokenGroup {
        let title: String
        var contents: [Any] = []
        
        init(title: String, contents: [Any]) {
            self.title = title
            self.contents = contents
        }
    }
    
    class AutocompleteViewController : NSViewController {
        init() {
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        
        override func loadView() {
            view = ContentView()
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        class ContentView : NSView, PopoverFirstResponderStealingSuppression {
            var suppressFirstResponderWhenPopoverShows: Bool { return true }
        }
    }
}
