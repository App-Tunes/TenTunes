//
//  Operators.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 09.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

// Operator acting similar to ?. in that it passes the value to a function if it exists.
infix operator ?=> : NilCoalescingPrecedence

extension Optional {
    static func ?=> <T>(left: Wrapped?, right: (Wrapped) -> T?) -> T? {
        if let left = left {
            return right(left)
        }
        return nil
    }
}

func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { a in { b in f(a, b) } }
}

