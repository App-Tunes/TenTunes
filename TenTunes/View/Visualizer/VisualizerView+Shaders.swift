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
        var _position: Attribute = .none
        
        var guResolution: Uniform = .none
        
        var guResonance: Uniform = .none
        var guResonanceDistortion: Uniform = .none
        var guResonanceDistortionSpeed: Uniform = .none
        var guResonanceDistortionShiftSizes: Uniform = .none
        
        var guResonanceColors: Uniform = .none
        var guResonanceColorsSoon: Uniform = .none
        var guResonanceCount: Uniform = .none
        
        var guTime: Uniform = .none
        
        var guMinDist: Uniform = .none
        var guDecay: Uniform = .none
        var guSharpness: Uniform = .none
        var guScale: Uniform = .none
        var guBrightness: Uniform = .none
        
        var guSpaceDistortion: Uniform = .none
        
        override func compile(vertex: String, fragment: String) throws {
            try super.compile(vertex: vertex, fragment: fragment)
            
            _position = find(attribute: "position")
            glEnableVertexAttribArray(GLuint(_position.rawValue))
            glVertexAttribPointer(GLuint(_position.rawValue), 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 4), nil)
            
            try checkAttributeError()

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
            
            try checkUniformError()
        }
    }
    
    class BloomShader: Shader {
        var _position: Attribute = .none

        var guImage: Uniform = .none

        var guResolution: Uniform = .none

        override func compile(vertex: String, fragment: String) throws {
            try super.compile(vertex: vertex, fragment: fragment)

            _position = find(attribute: "position")
            glEnableVertexAttribArray(GLuint(_position.rawValue))
            glVertexAttribPointer(GLuint(_position.rawValue), 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 4), nil)
            
            try checkAttributeError()
            
            guImage = find(uniform: "image")

            guResolution = find(uniform: "resolution")

            try checkUniformError()
        }
    }
}
