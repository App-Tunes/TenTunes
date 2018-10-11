//
//  RFOpenGLView+Swift.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 11.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension RFOpenGLView {
    @discardableResult
    static func checkGLError(_ description: String) -> Bool {
        let error = glGetError()
        
        guard error == 0 else {
            print("\(description): \(error)")
            return false
        }
        
        return true
    }
    
    static func timeMouseIdle() -> CFTimeInterval {
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
    }
}
