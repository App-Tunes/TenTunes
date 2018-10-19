//
//  SyphonableOpenGLView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class SyphonableOpenGLView: RFOpenGLView {
    enum DrawMode: Equatable {
        case direct
        case dont
        case redraw(textureID: GLuint)
    }
    
    var defaultShader = Shader()
    var drawMode: DrawMode = .direct
    
    override func setUpOpenGL() {
        super.setUpOpenGL()
        
        try! defaultShader.compile(vertexResource: "default", fragmentResource: "default")
    }
    
    override func wantsDisplayLink() -> Bool {
        return super.wantsDisplayLink() && drawMode == .direct
    }
    
    override func drawFrame() {
        switch drawMode {
        case .direct:
            drawSyphonableFrame()
        case .redraw(let textureID):
            defaultShader.bind()
            
//            glEnable(GLenum(GL_TEXTURE_RECTANGLE));
            glBindTexture(GLenum(GL_TEXTURE_RECTANGLE), textureID);
            
            drawFullScreenRect()
            
            glBindTexture(GLenum(GL_TEXTURE_RECTANGLE), 0);
//            glDisable(GLenum(GL_TEXTURE_RECTANGLE));
        case .dont:
            break
        }
    }
    
    func drawSyphonableFrame() {
        
    }
    
    func drawSyphonedFrame() {
        
    }
}
