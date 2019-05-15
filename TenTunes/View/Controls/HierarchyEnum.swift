//
//  HierarchyEnum.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 13.05.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

import Defaults

protocol HierarchyEnum: Equatable {
    static var hierarchy: [Self] { get }
}

extension HierarchyEnum {
    var ordinal: Int {
        return type(of: self).hierarchy.firstIndex(of: self) ?? -1
    }
}

class EnumCheckboxes<E: HierarchyEnum & Codable> {
    let key: Defaults.Key<E>
    let rawKey: Defaults.Key<String>

    let encode: (E) -> String
    let decode: (String) -> E

    init(key: Defaults.Key<E>, encode: @escaping (E) -> String, decode: @escaping (String) -> E?) {
        self.key = key
        self.encode = encode
        self.decode = { decode($0) ?? key.defaultValue }
        rawKey = Defaults.Key<String>(key.name, default: encode(key.defaultValue))
    }
    
    func bind(_ button: NSButton, as value: E) {
        let encode = self.encode
        let decode = self.decode
        
        let prev = E.hierarchy[(E.hierarchy.firstIndex(of: value) ?? 1) - 1]

        button.bind(.value, to: AppDelegate.defaults, withKeyPath: rawKey,
                    transform: { NSNumber(value: value.ordinal <= decode($0).ordinal) },
                    back: { encode(($0 as? NSNumber)?.boolValue == true ? value : prev) }
        )

        button.bind(.enabled, to: AppDelegate.defaults, withKeyPath: rawKey,
                    transform: { NSNumber(value: value.ordinal - 1 <= decode($0).ordinal) }
        )
    }
}
