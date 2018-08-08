//
//  RecursionGuard.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.08.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class RecursionGuard<E: Hashable> {
    var stack: Set<E> = Set()
    
    var failed: [Bool] = [false]
    
    var hasFailed: Bool {
        return failed.last!
    }
    
    func push(_ e: E) -> Bool {
        let (inserted, _) = stack.insert(e)
        if !inserted {
            // All upper levels failed too
            failed = failed.map { _ in true }
            failed.append(true)
        }
        else {
            failed.append(false)
        }
        return inserted
    }
    
    func pop(_ e: E) {
        stack.remove(e)
        failed.removeLast()
    }
}
