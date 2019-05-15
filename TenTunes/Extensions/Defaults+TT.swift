//
//  Defaults+TT.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 13.05.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

import Defaults

extension NSObject {
    // Only supported right now for native user defaults types
    open func bind<Object, Source>(_ binding: NSBindingName, to observable: Object, withKeyPath key: Defaults.Key<Source>, options: [NSBindingOption: Any] = [:], transform: ((Source) -> AnyObject?)? = nil, back: ((AnyObject?) -> Source)? = nil) {
        var options = options
        
        if let transform = transform {
            let backTransform: ((AnyObject?) -> Source?)? = back
            options[.valueTransformer] = SimpleTransformer<Source, AnyObject>(there: { transform($0 ?? key.defaultValue) }, back: backTransform)
        }
        
        bind(binding, to: observable, withKeyPath: key.name, options: options)
    }
}
