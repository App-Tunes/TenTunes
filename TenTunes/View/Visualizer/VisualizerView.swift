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
    func glUniform1fv(_ array: [GLfloat], as id: GLint) {
        array.map { GLfloat($0) }.withUnsafeBufferPointer {
            OpenGL.glUniform1fv(id, GLsizei(array.count), $0.baseAddress)
        }
    }
}

class VisualizerView: GLSLView {
    var currentFrequencies: [CGFloat] = []
    
    var guFrequencies: GLint = -1
    var guFrequencyColors: GLint = -1
    var guFreqCount: GLint = -1
    var guPointCount: GLint = -1

    func update(withFFT fft: [Double]) {
        let desiredLength = Int(log(Double(fft.count)) / log(2))
        if currentFrequencies.count != desiredLength {
            currentFrequencies = Array(repeating: 0, count: desiredLength)
        }
        
        let desiredDoubles: [Double] = (0 ..< currentFrequencies.count).map { idx in
            let start = Int((pow(2.0, Double(idx))) - 1)
            let end = Int((pow(2.0, Double(idx) + 1)) - 1)
            return fft[start ..< end].reduce(0, +)
            }
        
        let desired = desiredDoubles.map { CGFloat($0) }
            .map { max(0, $0 - 0.95) / 0.95 }

        currentFrequencies = Interpolation.linear(currentFrequencies, desired, amount: 0.2)
    }
    
    override func setupShaders() {
        super.setupShaders()
        guFrequencies = findUniform("frequencies")
        guFrequencyColors = findUniform("frequencyColors")
        guFreqCount = findUniform("freqCount")
        guPointCount = findUniform("pointCount")
    }
    
    override func uploadUniforms() {
        glUniform1i(guFreqCount, GLint(currentFrequencies.count))
        glUniform1i(guPointCount, GLint(currentFrequencies.count))

        glUniform1fv(currentFrequencies.map { GLfloat($0) }, as: guFrequencies)
        
        let colors = (0 ..< currentFrequencies.count).map {
            NSColor(hue: CGFloat($0) / CGFloat(currentFrequencies.count) * 0.8, saturation: 1.0, brightness: 0.5, alpha: 1)
        }
        glUniform1fv(colors.flatMap { [Float($0.redComponent), Float($0.greenComponent), Float($0.blueComponent)] }, as: guFrequencyColors)
    }
}
