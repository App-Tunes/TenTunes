//
//  HierarchyEnum.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 13.05.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

import Defaults

protocol HierarchyEnum: Comparable {
    static var hierarchy: [Self] { get }    
}

extension HierarchyEnum {
    var ordinal: Int {
        return type(of: self).hierarchy.firstIndex(of: self) ?? -1
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.ordinal < rhs.ordinal
    }
}

class EnumCheckboxes<E: HierarchyEnum & Codable> {
    let key: Defaults.Key<E>

    init(key: Defaults.Key<E>) {
        self.key = key
    }
    
    func bind(_ button: NSButton, as value: E) {
        let prev = E.hierarchy[(E.hierarchy.firstIndex(of: value) ?? 1) - 1]

        button.bind(.value, to: AppDelegate.defaults, withKey: key,
                    transform: { NSNumber(value: value <= $0) },
                    back: { ($0 as? NSNumber)?.boolValue == true ? value : prev }
        )

        button.bind(.enabled, to: AppDelegate.defaults, withKey: key,
                    transform: { NSNumber(value: value.ordinal - 1 <= $0.ordinal) }
        )
    }
}
