//
//  PopupEnum.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.04.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import Defaults

class PopupEnum<E : Equatable & Codable>: NSObject {
    let userDefaultsKey: Defaults.Key<E>
    let values: [E]
    
    @objc dynamic var selectedItem: Int {
        didSet {
            AppDelegate.defaults[userDefaultsKey] = values[selectedItem]
        }
    }

    init(userDefaultsKey: Defaults.Key<E>, values: [E]) {
        self.userDefaultsKey = userDefaultsKey
        self.values = values
        
        let current = AppDelegate.defaults[userDefaultsKey]
        selectedItem = (values.firstIndex { $0 == current }) ?? 0
    }
    
    static func bind(_ popup: NSPopUpButton, toUserDefaultsKey key: Defaults.Key<E>, with: [E], title: (E) -> String) {
        let controller = PopupEnum(userDefaultsKey: key, values: with)
        
        popup.removeAllItems()
        for item in with {
            popup.addItem(withTitle: title(item))
        }
        
        popup.bind(.init("selectedIndex"), to: controller, withKeyPath: "selectedItem", options: [:])
    }
    
    static func represent(in popup: NSPopUpButton, with: [E], title: (E) -> String) {
        popup.removeAllItems()
        
        for item in with {
            popup.addItem(withTitle: title(item))
            popup.menu!.items.last!.representedObject = item
        }
    }
}
