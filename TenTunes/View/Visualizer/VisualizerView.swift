//
//  VisualizerView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import OpenGL

extension GLSLView {
    func upload(_ array: [GLfloat], as id: GLint) {
        array.map { GLfloat($0) }.withUnsafeBufferPointer {
            glUniform1fv(id, GLsizei(array.count), $0.baseAddress)
        }
    }
}

class VisualizerView: GLSLView {

    var currentFrequencies: [CGFloat] = Array(repeating: 0, count: 10)
    
    var guFrequencies: GLint = -1
    var guFrequencyColors: GLint = -1
    
    func update(withFFT: [Double]) {
        let desired = withFFT.map { CGFloat($0) }
            .dropLast(16)
            .remap(toSize: currentFrequencies.count)
            .map { max(0, pow($0, 2) - 0.000001) }

        currentFrequencies = Interpolation.linear(currentFrequencies, desired, amount: 0.2)
    }
    
    override func setupShaders() {
        super.setupShaders()
        guFrequencies = findUniform("frequencies")
        guFrequencyColors = findUniform("frequencyColors")
    }
    
    override func uploadUniforms() {
        upload(currentFrequencies.map { GLfloat($0) }, as: guFrequencies)
        
        let colors = (0 ..< currentFrequencies.count).map {
            NSColor(hue: CGFloat($0) / CGFloat(currentFrequencies.count) * 0.8, saturation: 0.8, brightness: 0.5, alpha: 1)
        }
        upload(colors.flatMap { [Float($0.redComponent), Float($0.greenComponent), Float($0.blueComponent)] }, as: guFrequencyColors)
    }
}
