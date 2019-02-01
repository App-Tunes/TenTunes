//
//  LazyVar.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 01.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class LazyVar<O : NSObject, T> {
    let computer: (O) -> T
    var observers = [NSKeyValueObservation]()
    
    init(computer: @escaping (O) -> T) {
        self.computer = computer
    }
    
    func observe<T>(_ o: O, _ keyPaths: [KeyPath<O, T>]) {
        for path in keyPaths {
            observers.append(o.observe(path) { [unowned self] (o_, change) in
                self.reset()
            })
        }
    }
    
    var _value : T?
    
    func reset() {
        _value = nil
    }
    
    func value(_ o: O) -> T {
        if _value == nil {
            _value = computer(o)
        }
        
        return _value!
    }
}
