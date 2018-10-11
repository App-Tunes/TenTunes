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
    class DynamicTexture {
        var textureID: GLuint? = nil
        
        var size: CGSize = NSZeroSize {
            didSet {
                if oldValue != size { setSize() }
            }
        }
        
        @discardableResult
        func bind() -> Bool {
            create()
            glBindTexture(GLenum(GL_TEXTURE_2D), textureID!)
            
            return true
        }
        
        func create() {
            guard textureID == nil else {
                return
            }

            glGenTextures(1, &textureID!)
            glBindTexture(GLenum(GL_TEXTURE_2D), textureID!)
            
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
            
            setSize()
        }
        
        internal func setSize() {
            glBindTexture(GLenum(GL_TEXTURE_2D), textureID!)
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGB, GLsizei(size.width), GLsizei(size.height), 0, GLenum(GL_RGB), GLenum(GL_FLOAT), nil)
        }
    }
}
