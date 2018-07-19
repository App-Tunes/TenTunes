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
        
        SimpleTransformer<NSData, NSImage>.simple("NSImageTransformer",
                                                  there: { $0?.tiffRepresentation as NSData? },
                                                  back: { $0 != nil ? NSImage(data: $0! as Data) : nil }
        )
        
        DoubleTransformer.double("Pow2Transformer", there: curry(pow)(2), back: log2)
    }
}
