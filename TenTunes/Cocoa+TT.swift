//
//  NSString+TT.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 22.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension String {
    
}

extension Collection {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
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

extension Array where Iterator.Element == CGFloat {
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
}

extension NSTextField {
    func setStringColor(_ color: NSColor) {
        if let mutableAttributedTitle = self.attributedStringValue.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutableAttributedTitle.length))
            self.attributedStringValue = mutableAttributedTitle
        }
    }
}

extension NSButton {
    func set(text: String) {
        self.attributedTitle = NSAttributedString(string: text, attributes: self.attributedTitle.attributes(at: 0, effectiveRange: nil))
    }
    
    func set(color: NSColor) {
        if let mutableAttributedTitle = self.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutableAttributedTitle.length))
            self.attributedTitle = mutableAttributedTitle
        }
    }
}
