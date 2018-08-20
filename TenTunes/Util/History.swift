//
//  History.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 20.08.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class History<Element> : NSObject {
    var elements: [Element] = []
    @objc var index: Int = 0
    var defaultElement: Element
    
    var maxLength = 1000
    
    init(default element: Element) {
        defaultElement = element
    }
    
    var current: Element {
        return elements[safe: index] ?? defaultElement
    }
    
    @objc
    var canGoBack: Bool {
        return index > 0
    }
    
    class func keyPathsForValuesAffectingCanGoBack() -> Set<NSObject> {
        return Set(arrayLiteral: "elements", "index") as Set<NSObject>
    }

    @objc
    var canGoForwards: Bool {
        return index < count - 1
    }

    class func keyPathsForValuesAffectingCanGoFowards() -> Set<NSObject> {
        return Set(arrayLiteral: "elements", "index") as Set<NSObject>
    }

    func push(_ element: Element) {
        // +1 because 0...index is length index +1, and because we add another element later
        elements = (index < count - 1) ? Array(elements[max(index + 2 - maxLength, 0)...index]) : elements
        elements.append(element)
        index = count - 1
    }
    
    var count: Int {
        return elements.count
    }
    
    @discardableResult
    func back(skip: ((Element) -> Bool)? = nil) -> Element {
        index = max(0, index - 1)
        while index > 0 && (skip?(current) ?? false) {
            index -= 1
        }
        return current
    }
    
    @discardableResult
    func forwards(skip: ((Element) -> Bool)? = nil) -> Element {
        index = min(count - 1, index + 1)
        while index < count - 1 && (skip?(current) ?? false) {
            index -= 1
        }
        return current
    }
    
    func clear() {
        elements = []
        index = 0
    }
}
