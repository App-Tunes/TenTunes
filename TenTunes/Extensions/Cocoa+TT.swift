//
//  Cocoa+TT.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 09.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension NSImage {
    func tinted(in tint: NSColor) -> NSImage {
        guard let tinted = self.copy() as? NSImage else { return self }
        tinted.lockFocus()
        tint.set()
        
        let imageRect = NSRect(origin: NSZeroPoint, size: self.size)
        __NSRectFillUsingOperation(imageRect, .sourceAtop)
        
        tinted.unlockFocus()
        return tinted
    }
    
    func resized(w: Int, h: Int) -> NSImage {
        let destSize = NSMakeSize(CGFloat(w), CGFloat(h))
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        draw(in: NSMakeRect(0, 0, destSize.width, destSize.height), from: NSMakeRect(0, 0, size.width, size.height), operation: .sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.tiffRepresentation!)!
    }
}

extension NSTextField {
    func setStringColor(_ color: NSColor) {
        attributedStringValue = attributedStringValue.with(color, for: .foregroundColor)
    }
    
    func setAlignment(_ alignment: NSTextAlignment) {
        attributedStringValue = attributedStringValue.with(alignment: alignment)
    }
}

extension NSButton {
    func set(text: String) {
        self.attributedTitle = NSAttributedString(string: text, attributes: self.attributedTitle.attributes(at: 0, effectiveRange: nil))
    }
    
    func set(color: NSColor) {
        attributedTitle = attributedTitle.with(color, for: .foregroundColor)
    }
}

extension NSTableView {
    var clickedRows: [Int] {
        if isRowSelected(clickedRow) {
            return Array(selectedRowIndexes)
        }
        return [clickedRow]
    }
    
    func animateDifference<Element : Equatable>(from: [Element]?, to: [Element]?) {
        if let from = from, let to = to, let (left, right) = from.difference(from: to) {
            if (left ?? right!).count > 100 {
                // Give up, this will look shite anyhow
                reloadData()
            }
            else if let removed = left {
                removeRows(at: IndexSet(removed), withAnimation: .slideDown)
            }
            else if let added = right {
                insertRows(at: IndexSet(added), withAnimation: .slideUp)
            }
        }
        else if let from = from, let to = to, let movement = from.movement(to: to) {
            for (src, dst) in (movement.sorted { $0.1 > $1.1 }) {
                moveRow(at: src, to: dst)
            }
        }
        else {
            reloadData()
        }
    }
    
    func tableColumn(withIdentifier identifier: NSUserInterfaceItemIdentifier) -> NSTableColumn? {
        return tableColumns[safe: column(withIdentifier: identifier)]
    }
    
    func scrollRowToTop(_ row: Int) {
        scrollRowToVisible((row) + 100) // Scroll 'down' first so we have to scroll up after
        scrollRowToVisible(row)
    }
}

extension NSMenu {
    func item(withAction: Selector) -> NSMenuItem? {
        return items.filter { $0.action == withAction }.first
    }
}

extension NSWindow {
    func positionNextTo(view: NSView) {
        let windowPoint = view.convert(NSPoint(x: view.bounds.width, y: view.bounds.height / 2), to: nil)
        let screenPoint = view.window!.convertToScreen(NSRect(origin: windowPoint, size: .zero)).origin

        let size = self.frame.size
        var frame = NSRect(x: screenPoint.x, y: screenPoint.y - size.height / 2, width: size.width, height: size.height)

        let limit = view.window!.screen!.visibleFrame
        if frame.maxX > limit.maxX {
            frame.origin.x = limit.maxX - frame.size.width
        }
        
        setFrame(frame, display: true)
    }
}

extension NSOutlineView {
    func edit(row: Int, with event: NSEvent?, select: Bool) {
        editColumn(0, row: row, with: event, select: select)
    }
    
    func animateDelete(elements: [AnyObject]) {
        guard elements.count < 100 else {
            reloadData()
            return
        }
        
        for element in elements {
            let idx = childIndex(forItem: element)
            if idx >= 0 {
                removeItems(at: IndexSet(integer: idx), inParent: parent(forItem: element), withAnimation: .slideDown)
            }
        }
    }
    
    func animateInsert<T>(elements: [T], position: (T) -> (Int, T?)) {
        guard elements.count < 100 else {
            reloadData()
            return
        }
        
        for t in elements {
            let (pos, parent) = position(t)
            insertItems(at: IndexSet(integer: pos), inParent: parent, withAnimation: .slideUp)
        }
    }
}
