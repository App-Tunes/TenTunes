//
//  PopupEnum.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.04.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class PopupEnum<E>: NSObject {
    let userDefaultsKey: String
    let values: [E]
    let valueTransform: (E) -> String
    
    @objc dynamic var selectedItem: Int {
        didSet {
            UserDefaults.standard.set(valueTransform(values[selectedItem]), forKey: userDefaultsKey)
        }
    }

    init(userDefaultsKey: String, values: [E], valueTransform: @escaping (E) -> String) {
        self.userDefaultsKey = userDefaultsKey
        self.values = values
        self.valueTransform = valueTransform
        
        let current = UserDefaults.standard.value(forKey: userDefaultsKey) as? String
        selectedItem = (values.index { valueTransform($0) == current }) ?? 0
    }
    
    static func bind(_ popup: NSPopUpButton, toUserDefaultsKey: String, with: [E], by: @escaping (E) -> String, title: (E) -> String) {
        let controller = PopupEnum(userDefaultsKey: toUserDefaultsKey, values: with, valueTransform: by)
        
        popup.removeAllItems()
        for item in with {
            popup.addItem(withTitle: title(item))
        }
        
        popup.bind(.init(rawValue: "selectedIndex"), to: controller, withKeyPath: "selectedItem", options: [:])
    }
}
