//
//  SimpleTransformer.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 12.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension ValueTransformer {
    class func register(_ name: String, _ with: ValueTransformer) {
        setValueTransformer(with, forName: .init(rawValue: name))
    }
}

class SimpleTransformer<There : AnyObject, Back>: ValueTransformer {
    let there: (Any?) -> Any?
    let back: ((Any?) -> Any?)?
    
    override class func transformedValueClass() -> Swift.AnyClass { return There.self }
    
    init(there: @escaping (Back?) -> There?, back: ((There?) -> Back?)? = nil) {
        self.there = { there($0 as? Back) }
        self.back = back != nil ? { back!($0 as? There) } : nil
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        return there(value)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        return back!(value)
    }
}

extension SimpleTransformer {
    class func simple(_ name: String, there: @escaping (Back?) -> There?, back: ((There?) -> Back?)? = nil) {
        register(name, SimpleTransformer(there: there, back: back))
    }
}

class DoubleTransformer: SimpleTransformer<NSNumber, NSNumber> {
    class func optional(_ name: String, there: @escaping (Double?) -> Double?, back: ((Double?) -> Double?)? = nil) {
        let there: (NSNumber?) -> NSNumber? = { there($0?.doubleValue) ?=> NSNumber.init }
        let back: ((NSNumber?) -> NSNumber?)? = back != nil ? { back!($0?.doubleValue) ?=> NSNumber.init } : nil
        register(name, SimpleTransformer(there: there, back: back))
    }

    class func double(_ name: String, there: @escaping (Double) -> Double?, back: ((Double) -> Double?)? = nil) {
        let there: (NSNumber?) -> NSNumber? = { ($0?.doubleValue ?=> there) ?=> NSNumber.init }
        let back: ((NSNumber?) -> NSNumber?)? = back != nil ? { ($0?.doubleValue ?=> back!) ?=> NSNumber.init } : nil
        register(name, SimpleTransformer(there: there, back: back))
    }
}


//@objc class SomeTransformer: SimpleTransformer {
//    override class func transformedValueClass() -> Swift.AnyClass { return Some.self }
//}

