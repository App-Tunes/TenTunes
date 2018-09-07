//
//  Analysis.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 29.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

class Analysis : NSObject, NSCoding {
    static let sampleCount: Int = 500
    
    var values: [[CGFloat]]
    var complete = false
    
    required init?(coder aDecoder: NSCoder) {
        let decodedValues = aDecoder.decodeObject() as? [[UInt8]] ?? []
        
        if decodedValues.count != 4 { return nil }
        for wave in decodedValues {
            if !(wave.count == Analysis.sampleCount) {
                return nil
            }
        }
        
        values = decodedValues.map { $0.map { CGFloat($0) / 255.0 }}
        complete = true
    }
    
    override init() {
        values = Array(repeating: Array(repeating: 0.0, count: Analysis.sampleCount), count: 4)
    }
    
    func encode(with aCoder: NSCoder) {
        if !complete {
            fatalError("Not complete yet")
        }
        
        values = values.map { $0.map {
            guard $0.isNormal || $0.isZero else {
                print(String(format: "Found %f in analysis %s", $0, self))
                return 0
            }
            
            return $0
        }}
        
        aCoder.encode(values.map { $0.map { UInt8($0 * 255) }})
    }
    
    func set(from: Analysis) {
        values = from.values
        complete = from.complete
    }
}

