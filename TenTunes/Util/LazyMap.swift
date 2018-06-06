//
//  LazyMap.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 06.06.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class LazyMap<Index: Hashable, Element> {
    let map: (Index) -> Element
    var dict: [Index: Element] = [:]
    
    init(_ map: @escaping (Index) -> Element) {
        self.map = map
    }
    
    subscript (_ index: Index) -> Element {
        if let result = dict[index] {
            return result
        }
        
        let result = map(index)
        dict[index] = result
        
        return result
    }
}
