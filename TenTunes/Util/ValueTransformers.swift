//
//  Transformers.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 13.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class ValueTransformers {
    class func register() {
        SimpleTransformer<Key, AnyObject>.simple("MusicKeyTransformer",
                                                 there: { $0?.stringValue ?=> Key.parse },
                                                 back: { $0?.write as AnyObject }
        )

        DoubleTransformer.double("Pow2Transformer",
                                 there: { $0 ?=> curry(pow)(2) },
                                 back: { $0 ?=> log2 }
        )
    }
}
