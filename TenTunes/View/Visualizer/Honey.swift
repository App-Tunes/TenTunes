//
//  Honey.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 13.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Honey: Cloud {
    var defaultShader = DefaultShader()

    var bloom = BloomShader()
    var bloomState = PingPongFramebuffer()
    var pingPong = PingPongFramebuffer()
    
    override func setUpOpenGL() {
        super.setUpOpenGL()
        
        compile(shader: defaultShader, vertexResource: "default", fragmentResource: "default")
        compile(shader: bloom, vertexResource: "bloom", fragmentResource: "bloom")
        
        pingPong.size = bounds.size
        pingPong.create()
        
        bloomState.size = bounds.size
        bloomState.create()
        
        Framebuffer.unbind()
        Shader.unbind()
    }
    
    override func drawFrame() {
        glClearColor(0,0,0,0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        pingPong.size = bounds.size
        pingPong.start()
        
        bloomState.size = bounds.size
        
        // Draw Colors to Framebuffer
        shader.bind()
        uploadUniforms()
        drawFullScreenRect()
        
        pingPong.end(rebind: true)
        RFOpenGLView.checkGLError("Main Render Error")
        
        //        // Draw to Bloom Framebuffer
        bloom.bind()
        glUniform1i(bloom.guBloomImage.rawValue, 1)
        
        DynamicTexture.active(1) { bloomState.switch() }
        
        glUniform2f(bloom.guDirVec.rawValue, 0.001, 0)
        glUniform1f(bloom.guRetainer.rawValue, 0.46)
        glUniform1f(bloom.guAdder.rawValue, 0.1)
        drawFullScreenRect()
        
        DynamicTexture.active(1) { bloomState.switch() }
        
        glUniform2f(bloom.guDirVec.rawValue, 0, 0.001)
        glUniform1f(bloom.guRetainer.rawValue, 1)
        glUniform1f(bloom.guAdder.rawValue, 0)
        drawFullScreenRect()
        
        RFOpenGLView.checkGLError("Bloom Render Error")
        Framebuffer.unbind()
        
        // Draw original image to screen
        defaultShader.bind()
        //        glUniform1f(defaultShader.guAlpha.rawValue, 0.3)
        //        drawFullScreenRect()
        
        // Draw bloom image to screen
        bloomState.end(rebind: true)
        
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE));
        glUniform1f(defaultShader.guAlpha.rawValue, 1)
        drawFullScreenRect()
        glDisable(GLenum(GL_BLEND))
        RFOpenGLView.checkGLError("Blit Render Error")
        
        bloomState.end()
        Shader.unbind()
        
        RFOpenGLView.checkGLError("Render End Error")
    }
}
