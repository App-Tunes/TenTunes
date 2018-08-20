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
        elements = (index < count - 1) ? Array(elements[0...index]) : elements
        elements.append(element)
        index = count - 1
    }
    
    var count: Int {
        return elements.count
    }
    
    @discardableResult
    func back() -> Element {
        index = max(0, index - 1)
        return current
    }
    
    @discardableResult
    func forwards() -> Element {
        index = min(count - 1, index + 1)
        return current
    }
}
