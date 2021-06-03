//
//  Analysis.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

class Analysis : NSObject, NSCoding {
    @objc(_TtCC8TenTunes8Analysis9Completed)
    class Values : NSObject, NSCoding {
        let loudness: [Float]
        let pitch: [Float]

        required init?(coder aDecoder: NSCoder) {
            let decodedValues = aDecoder.decodeObject() as? [[UInt8]] ?? []
            
            if decodedValues.count != 2 { return nil }
            for wave in decodedValues {
                if !(wave.count == Analysis.sampleCount) {
                    return nil
                }
            }
            
            let floats = decodedValues.map { $0.map { Float($0) / 255.0 }}
            loudness = floats[0]
            pitch = floats[1]
        }

        func encode(with aCoder: NSCoder) {
            let values: [[Float]] = asArray.map { $0.map {
                guard $0.isNormal || $0.isZero else {
                    print(String(format: "Found %f in analysis %s", $0, self))
                    return 0
                }
                
                return $0
            }}
            
            aCoder.encode(values.map { $0.map { UInt8($0 * 255) }})
        }

        required init(loudness: [Float], pitch: [Float]) {
            self.loudness = loudness
            self.pitch = pitch
        }
        
        convenience init(fromArray values: [[Float]]) {
            self.init(loudness: values[0], pitch: values[1])
        }
        
        var asArray: [[Float]] {
            return [loudness, pitch]
        }
    }
    
    static let sampleCount: Int = 256
    
    var values: Values?
    var complete = false
    
    required init?(coder decoder: NSCoder) {
        complete = decoder.decodeBool(forKey: "complete")
        values = complete // if not, we don't values that will never be completed
            ? decoder.decodeObject(of: Values.self, forKey: "values")
            : nil
    }
    
    override init() {
        
    }
    
    var failed: Bool {
        return complete && values == nil
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(values, forKey: "values")
        coder.encode(complete, forKey: "complete")
    }
    
    func set(from: Analysis) {
        values = from.values
        complete = from.complete
    }
}

