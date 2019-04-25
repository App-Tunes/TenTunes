//
//  CacheRegistry.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

protocol ValidatableItem {
    var isValid: Bool { get }
}

class CacheRegistry<Item : ValidatableItem> {
    var dictionary: [String: Item] = [:]
    
    func get(_ key: String) -> Item? {
        dictionary = dictionary.filter { (_, item) in item.isValid }
        return dictionary[key]
    }

    func get(_ key: String, default provider: (String) -> Item) -> Item {
        if let item = get(key) {
            return item
        }
        
        let item = provider(key)
        dictionary[key] = item
        return item
    }
}
