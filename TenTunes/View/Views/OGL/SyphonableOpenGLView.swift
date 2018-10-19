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
    
    override func draw(_ dirtyRect: NSRect) {
        lockForDraw {
            switch self.drawMode {
            case .direct:
                self.prepareSyphonableFrame()
                self.drawSyphonableFrame()
            case .redraw(let textureID):
                // TODO Fix drawTextureFrame not working
//                self.drawTextureFrame(textureID: textureID)
                self.drawSyphonableFrame()
            default:
                break
            }
            
            self.openGLContext!.flushBuffer()
        }
    }
    
    func prepareSyphonableFrame() {
    }
    
    func drawSyphonableFrame() {
        glClearColor(0, 0, 0, 0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
    }
    
    func drawTextureFrame(textureID: GLuint) {
        glClearColor(0, 0, 0, 0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))

        defaultShader.bind()
        
//        glEnable(GLenum(GL_TEXTURE_RECTANGLE_EXT));
        glBindTexture(GLenum(GL_TEXTURE_RECTANGLE_EXT), textureID)
        
        drawFullScreenRect()
        
        glBindTexture(GLenum(GL_TEXTURE_RECTANGLE_EXT), 0)
//        glDisable(GLenum(GL_TEXTURE_RECTANGLE_EXT));
    }
}
