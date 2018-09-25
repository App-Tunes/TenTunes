//
//  Foundation+Collections.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 01.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    func noneSatisfy(_ predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
        return try allSatisfy { try !predicate($0) }
    }
    
    func anySatisfy(_ predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
        return try !noneSatisfy(predicate)
    }
}

extension Collection where Element : Equatable {
    var uniqueElement : Element? {
        guard count > 0 else {
            return nil
        }
        
        let result: Element? = first
        for element in self.dropFirst() {
            if element != result {
                return nil
            }
        }
        return result
    }
}

extension Collection where Iterator.Element == UInt8 {
    var toUInt: [UInt]  {
        return compactMap{ UInt($0) }
    }
}

extension Collection where Iterator.Element == UInt {
    var toCGFloat: [CGFloat]  {
        return compactMap { CGFloat($0) }
    }
}

extension Collection where Iterator.Element == Float {
    var toCGFloat: [CGFloat]  {
        return compactMap { CGFloat($0) }
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
    
    public func fullSlice() -> ArraySlice<Element> {
        return self[indices]
    }
    
    func of<T>(type: T.Type) -> [T] {
        return filter { $0 is T } as! [T]
    }
    
    var uniqueElements: [Element] {
        return Array<Any>(NSOrderedSet(array: self)) as! [Element]
    }
    
    var neighbors: Zip2Sequence<ArraySlice<Element>, ArraySlice<Element>> {
        return zip(self.dropLast(), self.dropFirst())
    }
    
    init(compact element: Element?) {
        self = element != nil ? [element!] : []
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
    
    public mutating func remove<C: Collection>(all: C) where C.Element == Element {
        self = removing(all: all)
    }
    
    public func removing<C: Collection>(all: C) -> [Element] where C.Element == Element {
        return filter { !all.contains($0) }
    }
    
    public mutating func rearrange(elements: [Element], to: Int) {
        rearrange(from: elements.map { self.index(of: $0)! }, to: to)
    }
    
    func flatten(by: (Element) -> [Element]?) -> [Element] {
        var all = self
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
    
    func movement(to: [Element]) -> [(Int, Int)]? {
        guard to.count == count else {
            return nil
        }
        
        // Direct approach
        guard to.count > 50 else {
            // Any more and it looks shit
            // Can reasonably do index(of)
            let indices = compactMap { to.index(of: $0) }
            // Everything has a unique index
            guard Set(indices).count == to.count else {
                return nil
            }
            var movement = indices.enumerated().map { ($0.0, $0.1) }
                //                .filter { $0.0 != $0.1 }
                .sorted { $0.1 < $1.1 }
            
            for i in 0..<movement.count {
                let (src, dst) = movement[i]
                movement[dst+1..<movement.count] = (movement[dst+1..<movement.count].map { (src2, dst2) in
                    return (src2 + (src2 < src ? 1 : 0), dst2)
                }).fullSlice()
            }
            
            return movement.filter { $0.0 != $0.1 }
        }
        
        let (left, right) = (self, to)
        
        var leftIdx = 0
        var rightIdx = 0
        
        var bucket: [Int] = []
        var movements: [(Int, Int)] = []
        
        // We run through both lists, keeping an irregularity bucket
        // Whenever the objects aren't the same, we check if we can use the first bucket object -> Movement
        // Otherwise we put the current objects at the end of the bucket
        while leftIdx < right.count || rightIdx < right.count {
            if rightIdx < right.count, leftIdx < left.count, left[leftIdx] == right[rightIdx] {
                leftIdx += 1
                rightIdx += 1
            }
            else if rightIdx < right.count, let first = bucket.first, left[first] == right[rightIdx] {
                movements.append((bucket.removeFirst(), rightIdx))
                rightIdx += 1
            }
            else if leftIdx < left.count {
                bucket.append(leftIdx)
                leftIdx += 1
            }
            else {
                return nil
            }
        }
        
        return bucket.count == 0 ? movements.sorted { $0.1 > $1.1 } : nil
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
            
            if trackRange.count == 0 {
                // TODO Needs lerp
                return self[trackRange.lowerBound]
            }
            
            return self[trackRange].reduce(0, +) / CGFloat(trackRange.count)
        }
    }
}

// Apparently these two can't be merged
extension ArraySlice where Iterator.Element == CGFloat {
    func remap(toSize: Int) -> [CGFloat] {
        return Array<Int>(0 ..< toSize).map { idx in
            let count = Int(self.count)
            let trackPosStart = Double(idx) / Double(toSize)
            let trackPosEnd = Double(idx + 1) / Double(toSize)
            let trackRange = (startIndex + Int(trackPosStart * Double(count))) ..< (startIndex + Int(trackPosEnd * Double(count)))
            
            return self[trackRange].reduce(0, +) / CGFloat(trackRange.count)
        }
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

extension Set {
    func of<T>(type: T.Type) -> Set<T> {
        return filter { $0 is T } as! Set<T>
    }
    
    mutating func remove<S : Sequence>(contentsOf other: S) where S.Element == Element {
        for t in other {
            remove(t)
        }
    }
    
    // TODO If possible, change to a possible mathematical v OR and add mathematical AND
    static func +(lhs: Set, rhs: Set) -> Set {
        return lhs.union(rhs)
    }
    
    static func shares(in ts: [Set]) -> (Set, Set) {
        guard !ts.isEmpty else {
            return (Set(), Set())
        }
        
        return ts.dropFirst().reduce((Set(), ts.first!)) { (acc, t) in
            var (omitted, shared) = acc
            
            omitted = omitted.union(t.symmetricDifference(shared))
            shared = shared.intersection(t)
            
            return (omitted, shared)
        }
    }
}
