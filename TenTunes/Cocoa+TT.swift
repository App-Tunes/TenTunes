//
//  NSString+TT.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Optional where Wrapped : Comparable {
    // Simply puts the nils at the end
    static func compare(_ lhs: Wrapped?, _ rhs: Wrapped?) -> Bool {
        if lhs == nil { return false }
        if rhs == nil { return true }
        return lhs! < rhs!
    }
}

extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    func allMatch(_ filter: (Element) -> Bool) -> Bool { return self.filter(filter).count == count }

    func noneMatch(_ filter: (Element) -> Bool) -> Bool { return self.filter(filter).count == 0 }

    func anyMatch(_ filter: (Element) -> Bool) -> Bool { return self.first(where: filter) != nil }
}

extension Collection where Iterator.Element == UInt8 {
    var toUInt: [UInt]  {
        return flatMap{ UInt($0) }
    }
}

extension Collection where Iterator.Element == UInt {
    var toCGFloat: [CGFloat]  {
        return flatMap{ CGFloat($0) }
    }
}

extension Collection where Iterator.Element == Float {
    var toCGFloat: [CGFloat]  {
        return flatMap{ CGFloat($0) }
    }
}

extension Collection where Iterator.Element == CGFloat {
    func normalized(min: CGFloat, max: CGFloat) -> [CGFloat] {
        return map { ($0 - min) / (max - min) }
    }
}

extension Array {
    mutating func remove(at indexes: [Int]) {
        for index in indexes.sorted(by: >) {
            remove(at: index)
        }
    }

    public mutating func rearrange(from: [Int], to: Int) {
        // First get the elements
        let elements = from.map { self[$0] }
        // Calculate by how much our index is going to be bumped down
        let toAfter = to - (from.filter { $0 < to }).count
        
        // Remove at indices
        remove(at: from)
        // Insert to new position
        insert(contentsOf: elements, at: toAfter)
    }
}

extension NSMutableOrderedSet {
    public func insert(all: [Any], at: Int) {
        // Reverse because it reverses again on insertion
        for element in all.reversed() {
            insert(element, at: at)
        }
    }
    
    public func rearrange(from: [Int], to: Int) {
        // First get the elements
        let elements = from.map { self[$0] }
        // Calculate by how much our index is going to be bumped down
        let toAfter = to - (from.filter { $0 < to }).count
        
        // Remove at indices
        self.removeObjects(at: IndexSet(from))
        // Insert to new position
        self.insert(all: elements, at: toAfter)
    }

    public func rearrange(elements: [Any], to: Int) {
        rearrange(from: (elements.map { self.index(of: $0) }), to: to)
    }
}

extension NSOrderedSet {
    public func rearranged(elements: [Any], to: Int) -> NSOrderedSet {
        let copy = mutableCopy() as! NSMutableOrderedSet
        copy.rearrange(elements: elements, to: to)
        return copy
    }
}

extension Array where Element: Equatable {
    @discardableResult
    public mutating func remove(element: Element) -> Bool {
        if let idx = self.index(of: element) {
            remove(at: idx)
            return true
        }
        return false
    }
    
    public mutating func remove(all: [Element]) {
        self = removing(all: all)
    }
    
    public func removing(all: [Element]) -> [Element] {
        return filter { !all.contains($0) }
    }
    
    public mutating func rearrange(elements: [Element], to: Int) {
        rearrange(from: elements.map { self.index(of: $0)! }, to: to)
    }
    
    static func flattened(root: Element, by: (Element) -> [Element]?) -> [Element] {
        var all = [root]
        var idx = 0
        
        while idx < all.count {
            if let children = by(all[idx]) {
                all += children
            }
            idx += 1
        }
        return all
    }
    
    static func path(of: Element, in root: Element, by: (Element) -> [Element]?) -> [Element]? {
        var searching = [[root]]
        
        while searching.count > 0 {
            let path = searching.removeFirst()
            
            if let children = by(path.last!) {
                if children.contains(of) {
                    return path + [of]
                }
                
                searching += children.map { path + [$0] }
            }
        }
        
        return nil
    }
    
    func sharesOrder(with: [Element]) -> Bool {
        let (left, right) = self.count < with.count ? (self, with) : (with, self)
        
        var rightIdx = -1
        
        for item in left {
            repeat {
                rightIdx += 1
                if rightIdx >= right.count {
                    return false
                }
            }
                while right[rightIdx] != item
        }
        
        return true
    }

    func difference(from: [Element]) -> ([Int]?, [Int]?)? {
        let leftSmaller = self.count < from.count
        let (left, right) = leftSmaller ? (self, from) : (from, self)
        var difference: [Int] = []
        difference.reserveCapacity(right.count - left.count)
        
        var rightIdx = -1
        
        for item in left {
            repeat {
                rightIdx += 1
                if rightIdx >= right.count {
                    return nil
                }
                
                // Add current item
                if right[rightIdx] != item { difference.append(rightIdx) }
            }
            while right[rightIdx] != item
        }
        
        // Add the rest
        difference += Array<Int>((rightIdx + 1)..<right.count)
        
        return leftSmaller ? (nil, difference) : (difference, nil)
    }
}

extension Array where Iterator.Element == CGFloat {
    mutating func remap(by: (Element) -> Element) {
        for i in 0..<count {
            self[i] = by(self[i])
        }
    }
    
    func remap(toSize: Int) -> [CGFloat] {
        return Array<Int>(0..<toSize).map { idx in
            let count = Int(self.count)
            let trackPosStart = Double(idx) / Double(toSize)
            let trackPosEnd = Double(idx + 1) / Double(toSize)
            let trackRange = Int(trackPosStart * Double(count))..<Int(trackPosEnd * Double(count))
            
            return self[trackRange].reduce(0, +) / CGFloat(trackRange.count)
        }
    }
}

// Apparently these two can't be merged
extension ArraySlice where Iterator.Element == CGFloat {
    func remap(toSize: Int) -> [CGFloat] {
        return Array<Int>(0..<toSize).map { idx in
            let count = Int(self.count)
            let trackPosStart = Double(idx) / Double(toSize)
            let trackPosEnd = Double(idx + 1) / Double(toSize)
            let trackRange = Int(trackPosStart * Double(count))..<Int(trackPosEnd * Double(count))
            
            return self[trackRange].reduce(0, +) / CGFloat(trackRange.count)
        }
    }
}

extension UInt32 {
    public static func random() -> UInt32 {
        return arc4random_uniform(UInt32.max)
    }
}

extension Int {
    public static func random() -> Int {
        return Int(arc4random_uniform(UInt32(Int.max)))
    }
    
    var minutesSeconds: (Int, Int) {
        return (self / 60, self % 60)
    }
    
    var timeString: String {
        let (m, s) = minutesSeconds
        return String(format: "\(m):%02d", s)
    }
}

extension ClosedRange where Bound == CGFloat {
    public func random() -> Bound {
        let range = self.upperBound - self.lowerBound
        return self.upperBound + (CGFloat(arc4random_uniform(UInt32.max)) / CGFloat(UInt32.max)) * range
    }
}

extension CountableRange where Bound == Int {
    public func random() -> Bound {
        let range = self.upperBound - self.lowerBound
        return self.lowerBound + Int(arc4random_uniform(UInt32(range)))
    }
}

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast((0..<Int(unshuffledCount)).random())
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

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

extension NSAttributedString {
    func with(_ value: Any, for key: NSAttributedStringKey) -> NSAttributedString {
        let mutableCopy = self.mutableCopy() as! NSMutableAttributedString
        mutableCopy.addAttribute(key, value: value, range: NSRange(location: 0, length: mutableCopy.length))
        return mutableCopy
    }
    
    func with(alignment: NSTextAlignment) -> NSAttributedString {
        let mutableCopy = self.mutableCopy() as! NSMutableAttributedString
        mutableCopy.setAlignment(alignment, range: NSRange(location: 0, length: mutableCopy.length))
        return mutableCopy
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
        else {
            reloadData()
        }
    }
}

infix operator ?=> : NilCoalescingPrecedence

extension Optional {
    static func ?=> <T>(left: Wrapped?, right: (Wrapped) -> T?) -> T? {
        if let left = left {
            return right(left)
        }
        return nil
    }
}

extension Dictionary {
    public mutating func removeValues(forKeys keys: [Key]) {
        for key in keys {
            removeValue(forKey: key)
        }
    }
}

extension Dictionary where Value : AnyObject {
    @discardableResult
    public mutating func insertNewValue(value: Value, forKey key: Key) -> Bool {
        let existing = self[key]
        if existing != nil && existing! === value { return false }
        else if existing != nil { fatalError("Duplicate ID") }
        self[key] = value
        return true
    }
}

extension String {
    subscript (r: CountableClosedRange<Int>) -> String {
        get {
            let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
            return String(self[startIndex...endIndex])
        }
    }
    
    var asFileName: String {
        let escaped = replacingOccurrences(of: "/", with: "\\:\\") // Escape
        return escaped.components(separatedBy: ":").joined(separator: "_") // Remove :
    }
}

extension NSManagedObject {
    func refresh(merge: Bool = false) {
        managedObjectContext!.refresh(self, mergeChanges: false)
    }
}

extension NSManagedObjectContext {
    public func convert<T : NSManagedObject>(_ t: T) -> T {
        return object(with: t.objectID) as! T
    }
}

extension NSMenu {
    func item(withAction: Selector) -> NSMenuItem? {
        return items.filter { $0.action == withAction }.first
    }
}

extension DispatchSemaphore {
    func acquireNow() -> Bool {
        return wait(timeout: DispatchTime.now()) == .success
    }
}

extension URL {
    func relativePath(from base: URL) -> String? {
        // Ensure that both URLs represent files:
        guard self.isFileURL && base.isFileURL else {
            return nil
        }
        
        // Remove/replace "." and "..", make paths absolute:
        let destComponents = self.standardized.pathComponents
        let baseComponents = base.standardized.pathComponents
        
        // Find number of common path components:
        var i = 0
        while i < destComponents.count && i < baseComponents.count
            && destComponents[i] == baseComponents[i] {
                i += 1
        }
        
        // Build relative path:
        var relComponents = Array(repeating: "..", count: baseComponents.count - i)
        relComponents.append(contentsOf: destComponents[i...])
        return relComponents.joined(separator: "/")
    }
}
