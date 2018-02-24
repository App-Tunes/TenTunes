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

extension Int {
    public static func random() -> Int {
        return Int(drand48() * Double(Int.max))
    }

    public func seed() {
        srand48(self)
    }
}

extension ClosedRange {
    public func random() -> Bound {
        let range = (self.upperBound as! CGFloat) - (self.lowerBound as! CGFloat)
        let randomValue = CGFloat(drand48()) * range + (self.lowerBound as! CGFloat)
        return randomValue as! Bound
    }
}

extension CountableRange {
    public func random() -> Bound {
        let range = (self.upperBound as! Int) - (self.lowerBound as! Int)
        let randomValue = Int(drand48() * Double(range)) + (self.lowerBound as! Int)
        return randomValue as! Bound
    }
}

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(Int(drand48() * Double(Int(unshuffledCount))))
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
