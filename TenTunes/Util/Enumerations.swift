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
    static func matches<P, A>(_ lhs: A, _ builder: @escaping (P) -> A) -> Bool {
        guard let lhsDecomposition = Mirror(reflecting: lhs).children.first,
            let lhsValue = lhsDecomposition.value as? P,
            let rhsDecomposition = Mirror(reflecting: builder(lhsValue)).children.first,
            lhsDecomposition.label == rhsDecomposition.label
            else { return false }
        
        return true
    }

    static func associatedValue<T, P>(of: T, as builder: @escaping (P) -> T) -> P? {
        guard Enumerations.matches(of, builder) else { return nil }
        // It HAS to be P, otherwise something is very wrong
        return Mirror(reflecting: of).children.first.map { $0.value as! P }
    }
}

extension Sequence {
    func caseLet<P>(_ builder: @escaping (P) -> Element) -> [P] {
        return compactMap { Enumerations.associatedValue(of: $0, as: builder) }
    }
}
