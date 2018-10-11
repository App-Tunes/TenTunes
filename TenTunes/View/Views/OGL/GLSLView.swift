//
//  GLSLView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class GLSLView: RFOpenGLView {
    var shader = Shader()

//    override func awakeFromNib() {
//        // 1. Create a context with opengl pixel format
//        let pixelFormatAttributes: [NSOpenGLPixelFormatAttribute] = [
//            UInt32(NSOpenGLPFAOpenGLProfile), UInt32(NSOpenGLProfileVersion3_2Core),
//            UInt32(NSOpenGLPFAColorSize)    , UInt32(24)                           ,
//            UInt32(NSOpenGLPFAAlphaSize)    , UInt32(8)                            ,
//            UInt32(NSOpenGLPFADoubleBuffer) ,
//            UInt32(NSOpenGLPFAAccelerated)  ,
//            UInt32(NSOpenGLPFANoRecovery)   ,
//            UInt32(0)
//        ]
//        if !isOpaque {
//            var opacity: GLint = 0
//            openGLContext?.setValues(&opacity, for: .surfaceOpacity)
//        }
//
//        pixelFormat = NSOpenGLPixelFormat(attributes: pixelFormatAttributes)
//
//        openGLContext!.makeCurrentContext()
//
//        super.awakeFromNib()
//
//        GLSLView.checkGLError("Setup GL Error")
//
//        glEnableVertexAttribArray(GLuint(shader.gaPosition.rawValue))
//        var null = 0
//        glVertexAttribPointer(GLuint(shader.gaPosition.rawValue), 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 4), &null)
//    }
    
    @discardableResult
    static func checkGLError(_ description: String) -> Bool {
        let error = glGetError()
        
        guard error == 0 else {
            print("\(description): \(error)")
            return false
        }
        
        return true
    }
    
    override func drawFrame() {
        super.drawFrame()
        
        guard shader.bind() else {
            print("Failed to bind shader for draw frame!")
            return
        }
        
        uploadUniforms()
        drawFullScreenRect()
    }
    
    func uploadUniforms() {
        
    }
    
    static func timeMouseIdle() -> CFTimeInterval {
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
    }
}
