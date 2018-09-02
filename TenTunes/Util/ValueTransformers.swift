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
        
        SimpleTransformer<NSData, NSImage>.simple("NSImageTransformerTIFF",
                                                  there: { $0?.tiffRepresentation as NSData? },
                                                  back: { $0 != nil ? NSImage(data: $0! as Data) : nil }
        )
        
        SimpleTransformer<NSData, NSImage>.simple("NSImageTransformerJPG",
                                                  there: { $0?.jpgRepresentation as NSData? },
                                                  back: { $0 != nil ? NSImage(data: $0! as Data) : nil }
        )
        
        SimpleTransformer<NSString, NSNumber>.simple("IntString",
                                                     there: { ($0 ?=> String.init) ?=> NSString.init },
                                                     back: { (($0 ?=> String.init) ?=> Int.init) ?=> NSNumber.init }
        )
        
        SimpleTransformer<NSString, NSNumber>.simple("IntStringNullable",
                                                     there: {
                                                        guard $0?.intValue != 0 else {
                                                            return nil
                                                        }
                                                        return ($0 ?=> String.init) ?=> NSString.init
        },
                                                     back: {
                                                        guard ($0?.length ?? 1) > 0 else {
                                                            return NSNumber(value: 0)
                                                        }
                                                        
                                                        return (($0 ?=> String.init) ?=> Int.init) ?=> NSNumber.init
        })
        
        DoubleTransformer.double("Pow2Transformer", there: curry(pow)(2), back: log2)
    }
}
