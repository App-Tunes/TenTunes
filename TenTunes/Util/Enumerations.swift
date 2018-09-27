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
        guard let elementTupleMirror = Mirror(reflecting: element).children.first,
            let elementDecomposition = Mirror(reflecting: elementTupleMirror.value).children.first else {
                return nil
        }
        guard let elementValue = elementDecomposition.value as? Value,
            let duplicateTupleMirror = Mirror(reflecting: builder(elementValue)).children.first,
            // Compare the resulting case names (params will always match)
            elementTupleMirror.label == duplicateTupleMirror.label
            else { return nil }
        
        // After we checked, it MUST be Value
        return elementValue
    }
}

extension Sequence {
    func caseLet<P>(_ builder: @escaping (P) -> Element) -> [P] {
        return compactMap { Enumerations.associatedValue(of: $0, as: builder) }
    }
}
