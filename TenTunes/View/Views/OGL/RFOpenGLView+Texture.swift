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
    class PingPongFramebuffer {
        let buffers: [Framebuffer]

        var targetIndex = 0

        var source: Framebuffer?
        var target: Framebuffer { return buffers[targetIndex] }

        var size: CGSize {
            set {
                buffers.forEach { $0.size = newValue }
            }
            get { return buffers.first!.size }
        }
        
        init(count: Int = 2) {
            buffers = (0 ..< count).map { _ in
                Framebuffer()
            }
        }

        func create() {
            buffers.forEach { $0.create() }
        }

        func start() {
            source?.texture.unbind()

            targetIndex = 0
            source = nil

            target.bind()
        }
        
        func next() {
            source = target
            targetIndex = (targetIndex + 1) % buffers.count
            
            target.bind()
            source!.texture.bind()
        }

        func end(rebind: Bool = false) {
            Framebuffer.unbind()
            source = target
            if rebind { source!.texture.bind() }
            else { source!.texture.unbind() }
        }
    }
    
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
        
        static var currentlyBound: GLuint {
            var fboID: GLint = 0
            glGetIntegerv(GLenum(GL_FRAMEBUFFER_BINDING), &fboID)
            return GLuint(fboID) // Will always be uint
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
            
            glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), texture.textureID, 0, 0);
            
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
        
        var image: CGImage? {
            didSet {
                upload()
            }
        }
        var size: CGSize {
            get { return _size }
            set {
                if _size != newValue, textureID > 0 {
                    _size = newValue
                    image = nil
                }
            }
        }
        var _size: CGSize = NSZeroSize

        class func active(_ unit: Int, run: () -> Void) {
            glActiveTexture(GLenum(Int(GL_TEXTURE0) + unit))
            run()
            glActiveTexture(GLenum(GL_TEXTURE0))
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
            
            // Nearest because we don't need to rescale anyway
            glTexParameteri(mode, GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST);
            glTexParameteri(mode, GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST);
            // Clamp because the texture should not need to repeat
            glTexParameteri(mode, GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
            glTexParameteri(mode, GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)

            upload()
        }
        
        internal func upload() {
            bind()
            
            guard let image = image else {
                glTexImage2D(mode, 0, GL_RGB, GLsizei(size.width), GLsizei(size.height), 0, GLenum(GL_RGB), GLenum(GL_FLOAT), nil)
                return
            }
            
            guard let data = image.dataProvider?.data else {
                fatalError("Unsupported image for texture!")
            }
            
            _size = NSSize(width: image.width, height: image.height)
            let samplesPerPixel = 3

            // Set proper unpacking row length for bitmap.
//            glPixelStorei(GLenum(GL_UNPACK_ROW_LENGTH), GLint(size.width))
            
            // Set byte aligned unpacking (needed for 3 byte per pixel bitmaps).
            glPixelStorei(GLenum(GL_UNPACK_ALIGNMENT), 1);

            glTexImage2D(mode, 0,
                         samplesPerPixel == 4 ? GL_RGBA8 : GL_RGB8,
                         GLsizei(size.width), GLsizei(size.height),
                         0,
                         GLenum(GL_RGBA),
                         GLenum(GL_UNSIGNED_BYTE),
                         CFDataGetBytePtr(data)
            )
        }
        
        func download() -> [UInt8] {
            var bytes: [UInt8] = Array(repeating: 0, count: Int(size.width * size.height * 4))
            bind()
            glGetTexImage(mode, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &bytes)
            return bytes
        }
    }
}
