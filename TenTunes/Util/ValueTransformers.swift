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
        SimpleTransformer<AnyObject, Key>.simple("MusicKeyTransformer",
                                                 there: { $0?.stringValue.flatMap(Key.parse) },
                                                 back: { $0?.write as AnyObject }
        )
        
        SimpleTransformer<NSImage, NSData>.simple("NSImageTransformerTIFF",
                                                  there: { $0?.tiffRepresentation as NSData? },
                                                  back: { $0 != nil ? NSImage(data: $0! as Data) : nil }
        )
        
        SimpleTransformer<NSImage, NSData>.simple("NSImageTransformerJPG",
                                                  there: { $0?.jpgRepresentation as NSData? },
                                                  back: { $0 != nil ? NSImage(data: $0! as Data) : nil }
        )
        
        SimpleTransformer<NSNumber, NSString>.simple("IntString",
                                                     there: { $0.map(String.init).map(NSString.init) },
                                                     back: { $0.map(String.init).flatMap(Int.init).map(NSNumber.init) }
        )
        
        SimpleTransformer<NSNumber, NSString>.simple("IntStringNullable",
                                                     there: {
                                                        guard $0?.intValue != 0 else {
                                                            return nil
                                                        }
                                                        return $0.map(String.init).map(NSString.init)
        },
                                                     back: {
                                                        guard ($0?.length ?? 1) > 0 else {
                                                            return NSNumber(value: 0)
                                                        }
                                                        
                                                        return $0.map(String.init).map(Int.init).map(NSNumber.init)
        })
        
        SimpleTransformer<NSNumber, NSString>.simple("FloatString",
                                                     there: { $0.map(String.init).map(NSString.init) },
                                                     back: { $0.map(String.init).flatMap(Float.init).map(NSNumber.init) }
        )
        
        SimpleTransformer<NSNumber, NSString>.simple("SimpleFloatString",
                                                     there: { ($0 as? Float).map { NSString(format: "%.2f", $0) } },
                                                     back: { ($0.map(String.init).flatMap(Float.init) ?? 0).map(NSNumber.init) }
        )
        
        DoubleTransformer.double("Pow2Transformer", there: log2, back: curry(pow)(2))
        DoubleTransformer.double("Pow2Transformer-5Off", there: {
            $0 == 0 ? -5 : log2($0)
        }, back: {
            $0 == -5 ? 0 : pow(2, $0)
        })
    }
}
