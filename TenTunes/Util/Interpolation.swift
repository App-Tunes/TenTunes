//
//  Interpolation.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.08.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Interpolation {
    static func linear(_ left: CGFloat, _ right: CGFloat, amount: CGFloat) -> CGFloat {
        if amount >= 1 { return right }
        else if amount <= 0 { return left }

        return left * (CGFloat(1.0) - amount) + right * amount
    }
    
    static func linear(_ left: [CGFloat], _ right: [CGFloat], amount: CGFloat) -> [CGFloat] {
        return zip(left, right).map { Interpolation.linear($0, $1, amount: amount) }
    }
}
