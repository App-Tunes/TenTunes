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
    
    func glUniform1f(_ uniform: Shader.Uniform, _ value: GLfloat) {
        OpenGL.glUniform1f(uniform.rawValue, value)
    }
    
    func glUniform2f(_ uniform: Shader.Uniform, _ value1: GLfloat, _ value2: GLfloat) {
        OpenGL.glUniform2f(uniform.rawValue, value1, value2)
    }
    
    func glUniform1i(_ uniform: Shader.Uniform, _ value: GLint) {
        OpenGL.glUniform1i(uniform.rawValue, value)
    }
    
    func glUniform1fv(_ uniform: Shader.Uniform, _ value: [GLfloat]) {
        glUniform1fv(uniform.rawValue, value)
    }
    
    func glUniform1fv(_ uniform: GLint, _ value: [GLfloat]) {
        value.withUnsafeBufferPointer {
            OpenGL.glUniform1fv(uniform, GLsizei(value.count), $0.baseAddress)
        }
    }
}

