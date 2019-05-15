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
    open func bind<Object, Source>(_ binding: NSBindingName, to observable: Object, withKey key: Defaults.Key<Source>, options: [NSBindingOption: Any] = [:], transform: ((Source) -> AnyObject?)? = nil, back: ((AnyObject?) -> Source)? = nil) {
        
        // From Defaults source
        let encode: (Source) -> String? = { value in
            guard let data = try? JSONEncoder().encode([value]) else {
                fatalError("Cannot convert \(value)")
            }
            return String(String(data: data, encoding: .utf8)!.dropFirst().dropLast())
        }
        let decode: (String) -> Source = { text in
            guard
                let data = "[\(text)]".data(using: .utf8),
                let decoded = try? JSONDecoder().decode([Source].self, from: data)
                else {
                    return key.defaultValue
            }
            
            return decoded.first ?? key.defaultValue
        }
        
        let ftransform: (String?) -> AnyObject? = { value in
            guard let value = value.map(decode) else {
                    return nil
            }
            
            return transform.map { $0(value) } ?? value as AnyObject
        }

        let fback: (AnyObject?) -> String? = { value in
            guard let value = (back.map { $0(value) } ?? (value as? Source)) else {
                return nil
            }
            
            return encode(value)
        }

        var options = options
        options[.valueTransformer] = SimpleTransformer<String, AnyObject>(there: ftransform, back: fback)

        bind(binding, to: observable, withKeyPath: key.name, options: options)
    }
}
