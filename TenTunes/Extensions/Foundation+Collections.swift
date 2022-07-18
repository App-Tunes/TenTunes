//
//  Foundation+Collections.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 01.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Array {
    subscript (safe index: Index) -> Element? {
        get { return indices.contains(index) ? self[index] : nil }
    }
    
    func reduce(_ nextPartialResult: (Element, Element) throws -> Element) rethrows -> Element? {
        if let f = first {
            return try dropFirst().reduce(f, nextPartialResult)
        }
        
        return nil
    }
    
    public func reduce(_ updateAccumulatingResult: (inout Element, Element) throws -> ()) rethrows -> Element? {
        if let f = first {
            return try dropFirst().reduce(into: f, updateAccumulatingResult)
        }
        
        return nil
    }
    
    mutating func pop(at: Int) -> Element {
        let obj = self[at]
        self.remove(at: at)
        return obj
    }
    
    mutating func popFirst(where fun: (Element) -> Bool) -> Element? {
        guard let idx = firstIndex(where: fun) else {
            return nil
        }
        return pop(at: idx)
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        get { return indices.contains(index) ? self[index] : nil }
    }
    
    var onlyElement : Element? {
        return count == 1 ? first! : nil
    }
    
    func noneSatisfy(_ predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
        return try allSatisfy { try !predicate($0) }
    }
    
    func anySatisfy(_ predicate: (Self.Element) throws -> Bool) rethrows -> Bool {
        return try !noneSatisfy(predicate)
    }
}

extension Array where Element : Sequence {
    func innerCrossProduct() -> AnySequence<[Element.Element]> {
        guard let start = first?.map({ [$0] }) else {
            return AnySequence([])
        }
        return dropFirst().reduce(AnySequence(start)) { (curCross, next) in
            AnySequence(
                curCross.crossProduct(next).lazy.map { (combination, add) in
                    combination + [add]
                }
            )
        }
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

extension Collection where Iterator.Element : BinaryInteger {
    var toCGFloat: [CGFloat]  {
        return compactMap { CGFloat($0) }
    }
    
    var toUInt: [UInt]  {
        return compactMap{ UInt($0) }
    }
}

extension Collection where Iterator.Element == Float {
    var toCGFloat: [CGFloat]  {
        return compactMap { CGFloat($0) }
    }
}

extension Collection where Iterator.Element : FloatingPoint {
    func normalized(min: Element, max: Element, clamp: Bool = false) -> [Element] {
        let converted =  map { ($0 - min) / (max - min) }
        return clamp ? converted.map { Swift.max(0, Swift.min(1, $0)) } : converted
    }
}

extension Array {
    mutating func remap(by: (Element) -> Element) {
        self = map(by)
    }

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
        if let idx = self.firstIndex(of: element) {
            remove(at: idx)
            return true
        }
        return false
    }
    
    public mutating func removeAll<C: Collection>(elements: C) where C.Element == Element {
        removeAll { elements.contains($0) }
    }
    
    public mutating func removeAll<C: Collection>(elements: C) where C.Element == Element, Element: Hashable {
        let set = (elements as? Set<Element>) ?? Set(elements)
        removeAll { set.contains($0) }
    }
    
    public func removing<C: Collection>(all: C) -> [Element] where C.Element == Element {
        return filter { !all.contains($0) }
    }
    
    public mutating func rearrange(elements: [Element], to: Int) {
        rearrange(from: elements.map { self.firstIndex(of: $0)! }, to: to)
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
}

extension Array where Element: Hashable {
    var dissimilarElements: [Element] {
        var buffer = [Element]()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}

extension Array where Iterator.Element: FloatingPoint {
    func remap(toSize: Int, default defaultValue: Element = 0) -> [Element] {
		if count == 0 {
			return Array(repeating: defaultValue, count: toSize)
		}
		
        return Array<Int>(0 ..< toSize).map { idx in
            let count = Int(self.count)
            let trackPosStart = Double(idx) / Double(toSize)
            let trackPosEnd = Double(idx + 1) / Double(toSize)
            let trackRange = Int(trackPosStart * Double(count))..<Int(trackPosEnd * Double(count))
            
            if trackRange.count == 0 {
                // TODO Needs lerp
                return self[trackRange.lowerBound]
            }
            
            return self[trackRange].reduce(0, +) / Element(trackRange.count)
        }
    }

    func rms(toSize: Int, default defaultValue: Element = 0) -> [Element] {
        if toSize <= count {
            return remap(toSize: toSize)
        }
        
        let squared = map { $0 * $0 }
        
        return Array<Int>(0 ..< toSize).map { idx in
            let count = Int(self.count)
            let trackPosStart = Double(idx) / Double(toSize)
            let trackPosEnd = Double(idx + 1) / Double(toSize)
            let trackRange = Int(trackPosStart * Double(count))..<Int(trackPosEnd * Double(count))
            
            return sqrt(squared[trackRange].reduce(0, +) / Element(trackRange.count))
        }
    }
}

// Apparently these two can't be merged
extension ArraySlice where Iterator.Element: FloatingPoint {
    func remap(toSize: Int, default defaultValue: Element = 0) -> [Element] {
        return Array<Int>(0 ..< toSize).map { idx in
            let count = Int(self.count)
            let trackPosStart = Double(idx) / Double(toSize)
            let trackPosEnd = Double(idx + 1) / Double(toSize)
            let trackRange = (startIndex + Int(trackPosStart * Double(count))) ..< (startIndex + Int(trackPosEnd * Double(count)))
            
            if trackRange.count == 0 {
                // TODO Needs lerp
                return count > 0
                    ? self[trackRange.lowerBound]
                    : defaultValue
            }

            return trackRange.count > 0
                ? self[trackRange].reduce(0, +) / Element(trackRange.count)
                : defaultValue
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
