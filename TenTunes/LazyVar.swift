//
//  LazyVar.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 20.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class LazyVar<G> {
    var _computed = false
    var _cached: G? = nil
    var _computer: (@escaping (G) -> Swift.Void) -> Swift.Void
    
    init(computer: @escaping (@escaping (G) -> Swift.Void) -> Swift.Void) {
        self._computer = computer
    }
    
    var value: G {
        if !_computed {
            _computer() { (ret) in
                self.set(val: ret)
            }
        }
        
        return _cached!
    }
    
    func set(val: G) {
        _cached = val
        _computed = true
    }
    
    func reset() {
        _computed = false
    }
    
    func async(completion: @escaping (G) -> Swift.Void) {
        if self._computed {
            completion(self.value)
            return
        }
        
        _computer() { (ret) in
            self.set(val: ret)
            completion(ret)
        }
    }
}
