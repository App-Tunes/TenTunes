//
//  Enumerations.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 05.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol ExposedAssociatedValues { }

extension ExposedAssociatedValues {
    func associatedValue<P>(as builder: @escaping (P) -> Self) -> P? {
        return Enumerations.associatedValue(of: self, as: builder)
    }
}

class Enumerations {
    static func associatedValue<Element, Value>(of element: Element, as builder: @escaping (Value) -> Element) -> Value? {
        // Mirror Representation goes like this:
        // ["caseName": Tuple["paramName": Value]]
        // So extract the tuple first, then the actual value
        guard let elementMirror = Mirror(reflecting: element).children.first else {
            return nil
        }
        
        // Now it's either the element tuple already (if enum was (_ key: value)
        // Or a tuple of name and value (if enum was (key: value)
        guard let elementTupleMirror = elementMirror.value is Value ? elementMirror : Mirror(reflecting: elementMirror.value).children.first else {
                return nil
        }
        
        guard let elementValue = elementTupleMirror.value as? Value,
            let duplicateTupleMirror = Mirror(reflecting: builder(elementValue)).children.first,
            // Compare the resulting case names (params will always match)
            elementMirror.label == duplicateTupleMirror.label
            else { return nil }
        
        // After we checked, it MUST be Value
        return elementValue
    }
    
    static func `is`<Element, Value>(_ element: Element, ofType builder: @escaping (Value) -> Element) -> Bool {
        return associatedValue(of: element, as: builder) != nil
    }
}

extension Sequence {
    // Note: Sequence must be of type [Enum]
    func caseLet<P>(_ builder: @escaping (P) -> Element) -> [P] {
        return compactMap { Enumerations.associatedValue(of: $0, as: builder) }
    }
}

extension Array {
    // Note: Sequence must be of type [Enum]
    func caseAs<P>(_ builder: @escaping (P) -> Element) -> [P]? {
        let result = caseLet(builder)
        return result.count == count ? result : nil
    }
}
