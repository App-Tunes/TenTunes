//
//  RFOpenGLView+Swift.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 11.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension RFOpenGLView {    
    static func timeMouseIdle() -> CFTimeInterval {
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
    }
}
