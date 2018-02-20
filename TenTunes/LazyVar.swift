//
//  LazyVar.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 20.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

// Make sure only one of these is running at the same time to avoid performance problems
let computeSemaphore = DispatchSemaphore(value: 1)

class LazyVar<G> {
    var _computed = false
    var _cached: G? = nil
    var _computer: () -> G
    
    init(computer: @escaping () -> G) {
        self._computer = computer
    }
    
    var value: G {
        if !_computed {
            self.set(val: self.fetch())
        }
        
        return _cached!
    }
    
    func fetch() -> G {
        return _computer()
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
        
        computeSemaphore.wait()
        DispatchQueue.global(qos: .userInitiated).async {
            let val = self.fetch()
            
            // Update on main thread
            DispatchQueue.main.async {
                self.set(val: val)
                completion(val)
            }
            computeSemaphore.signal()
        }
    }
}
