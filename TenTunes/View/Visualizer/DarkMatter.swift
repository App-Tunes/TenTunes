//
//  DarkMatter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 14.12.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class DarkMatter: Cloud {
    var bloom = BloomShader()
    var bloomState = PingPongFramebuffer(count: 2)
    var pingPong = PingPongFramebuffer()
    
    var subtracter = SubtractShader()

    override func setUpOpenGL() {
        super.setUpOpenGL()
        
        compile(shader: bloom, vertexResource: "default", fragmentResource: "bloom")
        compile(shader: subtracter, vertexResource: "default", fragmentResource: "subtract")

        pingPong.size = bounds.size
        pingPong.create()
        
        bloomState.size = bounds.size
        bloomState.create()
        
        Framebuffer.unbind()
        Shader.unbind()
    }
    
    override func prepareSyphonableFrame() {
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
        glUniform1i(bloom.guBloomImage, 1)
        
        DynamicTexture.active(1) { bloomState.next() }
        
        glUniform2f(bloom.guDirVec, 0.001, 0)
        glUniform1f(bloom.guRetainer, 0.49)
        glUniform1f(bloom.guAdder, 0.04)
        drawFullScreenRect()
        
        DynamicTexture.active(1) { bloomState.next() }
        
        glUniform2f(bloom.guDirVec, 0, 0.001)
        glUniform1f(bloom.guRetainer, 1)
        glUniform1f(bloom.guAdder, 0)
        drawFullScreenRect()
        
        RFOpenGLView.checkGLError("Bloom Render Error")
        Framebuffer.unbind()
    }
    
    override func drawSyphonableFrame() {
        glClearColor(0,0,0,0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        bloomState.end()
        pingPong.source!.texture.bind()
        DynamicTexture.active(1) { bloomState.source!.texture.bind() }

        subtracter.bind()
        glUniform1i(subtracter.guSubtract, 1)
        drawFullScreenRect()
        
        RFOpenGLView.checkGLError("Blit Render Error")
        
        bloomState.end()
        Shader.unbind()
        
        RFOpenGLView.checkGLError("Render End Error")
    }
}
