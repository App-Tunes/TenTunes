//
//  ForeignConstraint.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.10.20.
//  Copyright © 2020 ivorius. All rights reserved.
//

import Foundation

class ForeignConstraint {
    let constraint: NSLayoutConstraint

    var _activeConstraint: NSLayoutConstraint?

    init?(_ constraint: NSLayoutConstraint) {
        if constraint.firstItem == nil || constraint.secondItem == nil {
            return nil
        }
        
        self.constraint = constraint
    }
    
    func update() {
        if let _activeConstraint = _activeConstraint {
            constraint.firstItem?.removeConstraint(_activeConstraint)
        }
        
        // TODO Support other kinds lol. There must be a getter somewhere
        switch constraint.secondAttribute {
        case .width:
            _activeConstraint = NSLayoutConstraint(item: constraint.firstItem!, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: constraint.secondItem!.frame!.width)
            constraint.firstItem!.addConstraint(_activeConstraint!)
        default:
            fatalError()
        }
    }
}
