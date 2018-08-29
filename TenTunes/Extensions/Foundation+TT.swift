//
//  NSString+TT.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

func longZip<Sequence1, Sequence2>(_ sequence1: Sequence1, _ sequence2: Sequence2) -> [(Sequence1.Element?, Sequence2.Element?)] where Sequence1 : Sequence, Sequence2 : Sequence {
    var zipped : [(Sequence1.Element?, Sequence2.Element?)] = Array(zip(sequence1, sequence2).map { ($0.0 as Sequence1.Element?, $0.1 as Sequence2.Element?) })
    zipped.append(contentsOf: sequence1.dropFirst(zipped.count).map { ($0, nil) })
    zipped.append(contentsOf: sequence2.dropFirst(zipped.count).map { (nil, $0) })
    return zipped
}

extension Sequence {
    func crossProduct<T2:Sequence>(_ rhs : T2) -> AnySequence<(Iterator.Element,T2.Iterator.Element)>
    {
        return AnySequence (
            lazy.flatMap { x in rhs.lazy.map { y in (x,y) }}
        )
    }
    
    func retain(_ retainer: (Element) -> Bool) -> [Element] {
        return filter { !retainer($0) }
    }
}

extension Optional where Wrapped : Comparable {
    // Simply puts the nils at the end
    static func compare(_ lhs: Wrapped?, _ rhs: Wrapped?) -> Bool {
        if lhs == nil { return false }
        if rhs == nil { return true }
        return lhs! < rhs!
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

    func allMatch(_ filter: (Element) -> Bool) -> Bool { return self.first { !filter($0) } == nil }

    func noneMatch(_ filter: (Element) -> Bool) -> Bool { return !anyMatch(filter) }

    func anyMatch(_ filter: (Element) -> Bool) -> Bool { return self.first(where: filter) != nil }
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

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: Int = numericCast((0..<Int(unshuffledCount)).random())
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
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
}

extension String {
    subscript (r: CountableClosedRange<Int>) -> String {
        get {
            let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
            return String(self[startIndex...endIndex])
        }
    }
    
    subscript (r: CountablePartialRangeFrom<Int>) -> String {
        get {
            let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
            return String(self[startIndex..<endIndex])
        }
    }
    
    subscript (r: PartialRangeUpTo<Int>) -> String {
        get {
            let upperBound = r.upperBound >= 0 ? r.upperBound : count + r.upperBound
            let endIndex = self.index(startIndex, offsetBy: upperBound)
            return String(self[startIndex..<endIndex])
        }
    }

    var asFileName: String {
        return replacingOccurrences(of: ":", with: "_") // Remove :
            .replacingOccurrences(of: "/", with: ":") // : is a slash in filenames
    }
    
    func startsOrIsStarted(by string: String) -> Bool {
        return string.count > count ? string.starts(with: self) : starts(with: string)
    }
    
    static func random16Hex() -> String {
        return String(format:"%08X%08X", arc4random(), arc4random())
    }
    
    static func id(of object: AnyObject) -> String {
        return String(UInt(bitPattern: ObjectIdentifier(object)))
    }
}

extension DispatchSemaphore {
    func acquireNow() -> Bool {
        return wait(timeout: DispatchTime.now()) == .success
    }
    
    func signalAfter(seconds: Double, completion: (() -> Swift.Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .microseconds(Int(seconds * 1000000)), execute: {
            self.signal()
            completion?()
        })
    }
}

extension URL {
    func relativePath(from directory: URL) -> String? {
        // Ensure that both URLs represent files:
        guard self.isFileURL && directory.isFileURL else {
            return nil
        }
        
        // Remove/replace "." and "..", make paths absolute:
        let destComponents = self.standardized.pathComponents
        let baseComponents = directory.standardized.pathComponents
        
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
    
    func ensurePath() throws {
        try FileManager.default.createDirectory(at: self.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
    }

    func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true, attributes: nil)
    }
}

extension Timer {
    static func scheduledAsyncBlock(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping () -> Swift.Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            repeat {
                Thread.sleep(forTimeInterval: interval)
                block()
            }
            while(repeats)
        }
    }
    
    // Schedules many blocks that run after another
    // The time interval is for a whole cycle
    static func scheduledAsyncTickTock(withTimeInterval interval: TimeInterval, do blocks: [() -> Swift.Void]) {
        let singleInterval = interval / Double(blocks.count)
        DispatchQueue.global(qos: .userInitiated).async {
            var idx = 0
            while true {
                Thread.sleep(forTimeInterval: singleInterval)
                blocks[idx % blocks.count]()
                idx += 1
            }
        }
    }
}

extension NSRegularExpression {
    func matchStrings(in string: String) -> [String] {
        let results = matches(in: string, range: NSRange(string.startIndex..., in: string))
        return results.map {
            String(string[Range($0.range, in: string)!])
        }
    }

    func split(string: String) -> [String] {
        let results = matches(in: string, range: NSRange(string.startIndex..., in: string))
        let indices = [NSMakeRange(0, string.startIndex.encodedOffset)] + results.map { $0.range } + [NSMakeRange(string.endIndex.encodedOffset, 0)]
        
        return indices.neighbors.map { arg in
            let (prev, next) = arg
            let middle = NSMakeRange(prev.upperBound, next.lowerBound - prev.upperBound)
            return String(string[Range(middle, in: string)!])
        }
    }
}
