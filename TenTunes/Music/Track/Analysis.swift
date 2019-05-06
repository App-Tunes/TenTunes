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
        let waveform: [CGFloat]
        let lows: [CGFloat]
        let mids: [CGFloat]
        let highs: [CGFloat]

        required init?(coder aDecoder: NSCoder) {
            let decodedValues = aDecoder.decodeObject() as? [[UInt8]] ?? []
            
            if decodedValues.count != 4 { return nil }
            for wave in decodedValues {
                if !(wave.count == Analysis.sampleCount) {
                    return nil
                }
            }
            
            let floats = decodedValues.map { $0.map { CGFloat($0) / 255.0 }}
            waveform = floats[0]
            lows = floats[1]
            mids = floats[2]
            highs = floats[3]
        }

        func encode(with aCoder: NSCoder) {
            let values: [[CGFloat]] = asArray.map { $0.map {
                guard $0.isNormal || $0.isZero else {
                    print(String(format: "Found %f in analysis %s", $0, self))
                    return 0
                }
                
                return $0
            }}
            
            aCoder.encode(values.map { $0.map { UInt8($0 * 255) }})
        }
        
        static func placeholder(lows: CGFloat, mids: CGFloat, highs: CGFloat, count: Int) -> Values {
            return Values(
                waveform: Array(repeating: 0.1, count: count),
                lows: Array(repeating: lows, count: count),
                mids: Array(repeating: mids, count: count),
                highs: Array(repeating: highs, count: count)
            )
        }

        required init(waveform: [CGFloat], lows: [CGFloat], mids: [CGFloat], highs: [CGFloat]) {
            self.waveform = waveform
            self.lows = lows
            self.mids = mids
            self.highs = highs
        }
        
        convenience init(fromArray values: [[CGFloat]]) {
            self.init(waveform: values[0], lows: values[1], mids: values[2], highs: values[3])
        }
        
        var asArray: [[CGFloat]] {
            return [waveform, lows, mids, highs]
        }
        
        func interpolateAtan(to: Values, step: Int, max: Int) -> Values {
            return Values(fromArray: zip(asArray, to.asArray).map { Interpolation.atan($0.0, $0.1, step: step, max: max) })
        }

        func interpolateLinear(to: Values, by amount: CGFloat) -> Values {
            return Values(fromArray: zip(asArray, to.asArray).map { Interpolation.linear($0.0, $0.1, amount: amount) })
        }
        
        func remapped(toSize size: Int) -> Values {
            return Values(fromArray: asArray.map { $0.remap(toSize: size) })
        }
    }
    
    static let sampleCount: Int = 500
    
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

