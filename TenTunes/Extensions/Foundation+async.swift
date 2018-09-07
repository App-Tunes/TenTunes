//
//  Foundation+async.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Timer {
    static func scheduledAsyncBlock(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping () -> Swift.Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            repeat {
                Thread.sleep(forTimeInterval: interval)
                block()
            }
                while(repeats)
        }
    }
    
    // Schedules many blocks that run after another
    // The time interval is for a whole cycle
    static func scheduledAsyncTickTock(withTimeInterval interval: TimeInterval, do blocks: [() -> Swift.Void]) {
        let singleInterval = interval / Double(blocks.count)
        DispatchQueue.global(qos: .userInitiated).async {
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
