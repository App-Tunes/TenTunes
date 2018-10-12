//
//  VisualizerView+Shaders.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 12.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension VisualizerView {
    class ColorShader: Shader {
        var _position: Shader.Attribute = .none
        
        var guResolution: Shader.Uniform = .none
        
        var guResonance: Shader.Uniform = .none
        var guResonanceDistortion: Shader.Uniform = .none
        var guResonanceDistortionSpeed: Shader.Uniform = .none
        var guResonanceDistortionShiftSizes: Shader.Uniform = .none
        
        var guResonanceColors: Shader.Uniform = .none
        var guResonanceColorsSoon: Shader.Uniform = .none
        var guResonanceCount: Shader.Uniform = .none
        
        var guTime: Shader.Uniform = .none
        
        var guMinDist: Shader.Uniform = .none
        var guDecay: Shader.Uniform = .none
        var guSharpness: Shader.Uniform = .none
        var guScale: Shader.Uniform = .none
        var guBrightness: Shader.Uniform = .none
        
        var guSpaceDistortion: Shader.Uniform = .none
        
        override func compile(vertex: String, fragment: String) throws {
            try super.compile(vertex: vertex, fragment: fragment)
            
            _position = find(attribute: "position")
            glEnableVertexAttribArray(GLuint(_position.rawValue))
            glVertexAttribPointer(GLuint(_position.rawValue), 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 4), nil)
            
            guard RFOpenGLView.checkGLError("Attribute Error") else {
                throw CompileFailure.attribute
            }
            
            guResolution = find(uniform: "resolution")
            
            guResonance = find(uniform: "resonance")
            guResonanceDistortion = find(uniform: "resonanceDistortion")
            guResonanceDistortionSpeed = find(uniform: "resonanceDistortionSpeed")
            guResonanceDistortionShiftSizes = find(uniform: "resonanceDistortionShiftSizes")
            
            guResonanceColors = find(uniform: "resonanceColors")
            guResonanceColorsSoon = find(uniform: "resonanceColorsSoon")
            guResonanceCount = find(uniform: "resonanceCount")
            
            guTime = find(uniform: "time")
            
            guMinDist = find(uniform: "minDist")
            guDecay = find(uniform: "decay")
            guSharpness = find(uniform: "sharpness")
            guScale = find(uniform: "scale")
            guBrightness = find(uniform: "brightness")
            
            guSpaceDistortion = find(uniform: "spaceDistortion")
            
            guard RFOpenGLView.checkGLError("Uniform Error") else {
                throw CompileFailure.uniform
            }
        }
    }
}
