//
//  RFOpenGLView+Texture.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import OpenGL

extension RFOpenGLView {
//    class PingPongFramebuffer {
//        let left = Framebuffer()
//        let right = Framebuffer()
//
//        var isLeft = false
//
//        var size: CGSize {
//            set {
//                left.size = newValue
//                right.size = newValue
//            }
//            get { return left.size }
//        }
//
//        func create() {
//            left.create()
//            right.create()
//        }
//
//        func ping() {
//            isLeft = !isLeft
//            (isLeft ? left : right).bind()
//        }
//
//        func pong() {
//            Framebuffer.unbind()
//            (isLeft ? left : right).texture.bind()
//        }
//    }
    
    class Framebuffer {
        let texture = DynamicTexture()
        var framebufferID: GLuint = 0;
        
        var size: CGSize {
            set { texture.size = newValue }
            get { return texture.size }
        }
        
        class func unbind() {
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0);
        }
        
        func bind() {
            create()
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebufferID);
        }
        
        func create() {
            guard framebufferID == 0 else {
                return
            }
            
            texture.create()
            
            glGenFramebuffers(1, &framebufferID);
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebufferID);
            
            glFramebufferTexture(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), texture.textureID, 0);
            
            let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
            if status != GL_FRAMEBUFFER_COMPLETE {
                print("Invalid framebuffer status: \(status)")
            }
        }
    }
    
    class DynamicTexture {
        var textureID: GLuint = 0
        var mode: GLenum
        
        init(mode: GLint = GL_TEXTURE_2D) {
            self.mode = GLenum(mode)
        }
        
        var size: CGSize = NSZeroSize {
            didSet {
                if oldValue != size, textureID > 0 {
                    setSize()
                }
            }
        }
        
        @discardableResult
        func bind() -> Bool {
            create()
            glBindTexture(mode, textureID)
            
            return true
        }
        
        func unbind() {
            glBindTexture(mode, 0)
        }
        
        func create() {
            guard textureID == 0 else {
                return
            }

            glGenTextures(1, &textureID)
            glBindTexture(mode, textureID)
            
            glTexParameteri(mode, GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);
            glTexParameteri(mode, GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);
            glTexParameteri(mode, GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
            glTexParameteri(mode, GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
            
            setSize()
        }
        
        internal func setSize() {
            bind()
            glTexImage2D(mode, 0, GL_RGB, GLsizei(size.width), GLsizei(size.height), 0, GLenum(GL_RGB), GLenum(GL_FLOAT), nil)
        }
        
        func download() -> [UInt8] {
            var bytes: [UInt8] = Array(repeating: 0, count: Int(size.width * size.height * 4))
            bind()
            glGetTexImage(mode, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &bytes)
            return bytes
        }
    }
}
