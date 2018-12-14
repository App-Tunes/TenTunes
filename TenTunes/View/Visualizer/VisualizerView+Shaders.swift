//
//  VisualizerView+Shaders.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 12.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension VisualizerView {
    class Shared: Shader {
        var _position: Attribute = .none

        var guResolution: Uniform = .none
        var guTime: Uniform = .none
        
        override func compile(vertex: String, fragment: String) throws {
            try super.compile(vertex: vertex, fragment: fragment)
            
            _position = find(attribute: "position")
            glEnableVertexAttribArray(GLuint(_position.rawValue))
            glVertexAttribPointer(GLuint(_position.rawValue), 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 4), nil)
            
            try checkAttributeError()
            
            guResolution = find(uniform: "resolution")
            guTime = find(uniform: "time")
        }
    }
    
    class DefaultShader: Shared {
        var guAlpha: Uniform = .none
        
        override func compile(vertex: String, fragment: String) throws {
            try super.compile(vertex: vertex, fragment: fragment)
            guAlpha = find(uniform: "alpha")
        }    }
    
    class ColorShader: Shared {
        var guResonance: Uniform = .none
        var guResonanceDistortion: Uniform = .none
        var guResonanceDistortionSpeed: Uniform = .none
        var guResonanceDistortionShiftSizes: Uniform = .none
        
        var guResonanceColors: Uniform = .none
        var guResonanceColorsSoon: Uniform = .none
        var guResonanceCount: Uniform = .none
        
        var guMinDist: Uniform = .none
        var guDecay: Uniform = .none
        var guSharpness: Uniform = .none
        var guScale: Uniform = .none
        var guBrightness: Uniform = .none
        
        var guSpaceDistortion: Uniform = .none
        
        override func compile(vertex: String, fragment: String) throws {
            try super.compile(vertex: vertex, fragment: fragment)
            
            guResonance = find(uniform: "resonance")
            guResonanceDistortion = find(uniform: "resonanceDistortion")
            guResonanceDistortionSpeed = find(uniform: "resonanceDistortionSpeed")
            guResonanceDistortionShiftSizes = find(uniform: "resonanceDistortionShiftSizes")
            
            guResonanceColors = find(uniform: "resonanceColors")
            guResonanceColorsSoon = find(uniform: "resonanceColorsSoon")
            guResonanceCount = find(uniform: "resonanceCount")
            
            guMinDist = find(uniform: "minDist")
            guDecay = find(uniform: "decay")
            guSharpness = find(uniform: "sharpness")
            guScale = find(uniform: "scale")
            guBrightness = find(uniform: "brightness")
            
            guSpaceDistortion = find(uniform: "spaceDistortion")
            
            try checkUniformError()
        }
    }
    
    class BloomShader: Shared {
        var guImage: Uniform = .none
        var guBloomImage: Uniform = .none

        var guDirVec: Uniform = .none
        
        var guRetainer: Uniform = .none
        var guAdder: Uniform = .none

        override func compile(vertex: String, fragment: String) throws {
            try super.compile(vertex: vertex, fragment: fragment)
            
            guImage = find(uniform: "image")
            guBloomImage = find(uniform: "bloom")

            guDirVec = find(uniform: "dirVec")

            guRetainer = find(uniform: "retainer")
            guAdder = find(uniform: "adder")

            try checkUniformError()
        }
    }
    
    class SubtractShader: Shared {
        var guSource: Uniform = .none
        var guSubtract: Uniform = .none

        override func compile(vertex: String, fragment: String) throws {
            try super.compile(vertex: vertex, fragment: fragment)
            
            guSource = find(uniform: "source")
            guSubtract = find(uniform: "subtract")
            
            try checkUniformError()
        }
    }
}
