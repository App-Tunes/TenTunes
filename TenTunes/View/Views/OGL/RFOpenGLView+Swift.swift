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
    
    func glUniform1fv(_ uniform: GLint, _ array: [GLfloat]) {
        array.withUnsafeBufferPointer {
            OpenGL.glUniform1fv(uniform, GLsizei(array.count), $0.baseAddress)
        }
    }
}
