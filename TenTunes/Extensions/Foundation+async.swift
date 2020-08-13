//
//  Foundation+async.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Timer {
    static func scheduledAsyncBlock(withTimeInterval interval: TimeInterval, qos:  DispatchQoS.QoSClass = .default, repeats: Bool, block: @escaping () -> Swift.Void) {
        DispatchQueue.global(qos: qos).async {
            repeat {
                Thread.sleep(forTimeInterval: interval)
                block()
            }
                while(repeats)
        }
    }
    
    // Schedules many blocks that run after another
    // The time interval is for a whole cycle
    static func scheduledAsyncTickTock(withTimeInterval interval: TimeInterval, qos:  DispatchQoS.QoSClass = .default, do blocks: [() -> Swift.Void]) {
        let singleInterval = interval / Double(blocks.count)
        DispatchQueue.global(qos: qos).async {
            var idx = 0
            while true {
                Thread.sleep(forTimeInterval: singleInterval)
                blocks[idx % blocks.count]()
                idx += 1
            }
        }
    }
}

extension Thread {
    static func activelyWait(interval: TimeInterval = 0.001, until: () -> Bool) {
        while true {
            if until() {
                return
            }
            
            Thread.sleep(forTimeInterval: interval)
        }
    }
}
