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

struct ArrayZipSequence<SequenceT> : Sequence where SequenceT : Sequence {
    typealias Element = [SequenceT.Element]
    
    let sequences: [SequenceT]
    
    init(_ sequences: [SequenceT]) {
        self.sequences = sequences
    }
    
    func makeIterator() -> ArrayZipIterator<SequenceT.Iterator> {
        return ArrayZipIterator(sequences.map { $0.makeIterator() })
    }
}

struct ArrayZipIterator<Iterator>: IteratorProtocol where Iterator : IteratorProtocol {
    typealias Element = [Iterator.Element]
    
    var iterators: [Iterator]
    
    init(_ iterators: [Iterator]) {
        self.iterators = iterators
    }
    
    mutating func next() -> Element? {
        let step: [(Iterator, Iterator.Element)] = iterators.compactMap { it in
            var iterator = it
            if let element = iterator.next() {
                return (iterator, element)
            }
            return nil
        }
        
        guard step.count == iterators.count else {
            return nil
        }
        
        iterators = step.map { $0.0 }
        return step.map { $0.1 }
    }
}

func arrayZip<Sequence1>(_ sequences: [Sequence1]) -> ArrayZipSequence<Sequence1> where Sequence1 : Sequence {
    return ArrayZipSequence(sequences)
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

extension Int {
    var minutesSeconds: (Int, Int) {
        return (self / 60, self % 60)
    }
    
    var timeString: String {
        let (m, s) = minutesSeconds
        return String(format: "%d:%02d", m, s)
    }
    
    init(bitComponents : [Int]) {
        self = bitComponents.reduce(0, +)
    }
    
    var bitComponents : [Int] {
        return (0 ..< Int.bitWidth).map { 1 << $0 } .filter { self & $0 != 0 }
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
    
    var asSimpleFileName: String {
        // Remove diacritics
        let simplified = asFileName.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: nil)
        // Remove everything else
        return Character.regexNotSimplePosix.stringByReplacingMatches(in: simplified, range: NSMakeRange(0, simplified.count), withTemplate: "")
    }
    
    var filterAlphanumeric: String {
        return Character.regexNotAlphanumeric.stringByReplacingMatches(in: self, range: NSMakeRange(0, count), withTemplate: "")
    }
    
    func startsOrIsStarted(by string: String) -> Bool {
        return string.count > count ? string.starts(with: self) : starts(with: string)
    }
    
    static func random16Hex() -> String {
        return String(format:"%08X%08X", Int.random(in: Int.min...Int.max), Int.random(in: Int.min...Int.max))
    }
    
    static func id(of object: AnyObject) -> String {
        return String(UInt(bitPattern: ObjectIdentifier(object)))
    }
}

extension Character {
    static var regexNotAlphanumeric = try! NSRegularExpression(pattern: "[^A-Za-z0-9]+", options: [])
    static var regexNotSimplePosix = try! NSRegularExpression(pattern: "[^A-Za-z0-9_\\-, ]+", options: [])
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
    
    func ensurePathExists() throws {
        try FileManager.default.createDirectory(at: self.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
    }

    func ensureIsDirectory() throws {
        try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true, attributes: nil)
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

extension OptionSet where RawValue == Int, Self == Self.Element {
    static var all : Self {
        return self.init(rawValue: Int.max)
    }
    
    var components : [Self] {
        return rawValue.bitComponents.map { return type(of: self).init(rawValue: $0) }
    }
}

extension Mirror {
    func child(withName name: String) -> Mirror.Child? {
        for child in children {
            if child.label == name {
                return child
            }
        }
        
        return nil
    }
}

extension Date {
    func isBefore(date: Date) -> Bool {
        return timeIntervalSinceReferenceDate < date.timeIntervalSinceReferenceDate
    }
    
    func isAfter(date: Date) -> Bool {
        return timeIntervalSinceReferenceDate > date.timeIntervalSinceReferenceDate
    }
}

extension UUID {
    // Meh, lol
    // Probably better with pointer magic
    static func ^(_ left: UUID, _ right: UUID) -> UUID {
        let (
            l0, l1, l2, l3, l4, l5, l6, l7,
            l8, l9, la, lb, lc, ld, le, lf
        ) = left.uuid
        let (
            r0, r1, r2, r3, r4, r5, r6, r7,
            r8, r9, ra, rb, rc, rd, re, rf
        ) = right.uuid
        
        return UUID(uuid: (
            l0 ^ r0, l1 ^ r1, l2 ^ r2, l3 ^ r3, l4 ^ r4, l5 ^ r5, l6 ^ r6, l7 ^ r7,
            l8 ^ r8, l9 ^ r9, la ^ ra, lb ^ rb, lc ^ rc, ld ^ rd, le ^ re, lf ^ rf
        ))
    }
}
