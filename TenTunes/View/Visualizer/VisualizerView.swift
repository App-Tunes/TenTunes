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
    static let resonanceOverlap = 2
    
    var currentFrequencies: [CGFloat] = []

    var guResolution: GLint = -1

    var guFrequencies: GLint = -1
    var guFrequencyDistortionShiftSizes: GLint = -1
    var guFrequencyColors: GLint = -1
    var guFreqCount: GLint = -1
    
    var guTime: GLint = -1
    
    var startDate = NSDate()

    func update(withFFT fft: [Double]) {
        let desiredLength = Int(log(Double(fft.count)) / log(2)) - VisualizerView.resonanceOverlap
        if currentFrequencies.count != desiredLength {
            currentFrequencies = Array(repeating: 0, count: desiredLength)
        }
        
        let desiredDoubles: [Double] = (0 ..< currentFrequencies.count).map { idx in
            let start = Int((pow(2.0, Double(idx))) - 1)
            // We do +2 so we have an overlap between similar frequencies
            let end = Int((pow(2.0, Double(idx + VisualizerView.resonanceOverlap + 1))) - 1)
            // Don't divide by size since this is how we hear it too
            return fft[start ..< end].reduce(0, +)
            }
        
        let desired = desiredDoubles.map { CGFloat($0) }

        currentFrequencies = Interpolation.linear(currentFrequencies, desired, amount: 0.15)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let vertexPath = Bundle.main.path(forResource: "visualizer", ofType: "vs"),
            let fragmentPath = Bundle.main.path(forResource: "visualizer", ofType: "fs"),
            let vertex = try? String(contentsOfFile: vertexPath),
            let fragment = try? String(contentsOfFile: fragmentPath)
            else {
                print("Failed to load shaders!")
                return
        }
        
        compileShaders(vertex, fragment: fragment)
        
        guResolution = findUniform("resolution")
        
        guFrequencies = findUniform("frequencies")
        guFrequencyDistortionShiftSizes = findUniform("frequencyDistortionShiftSizes")
        guFrequencyColors = findUniform("frequencyColors")
        guFreqCount = findUniform("freqCount")
        
        guTime = findUniform("time")
    }
    
    override func uploadUniforms() {
        let freqCount = currentFrequencies.count
        
        let time = -startDate.timeIntervalSinceNow
        glUniform1f(guTime, GLfloat(time));
        glUniform2f(guResolution, GLfloat(bounds.size.width), GLfloat(bounds.size.height));

        glUniform1i(guFreqCount, GLint(freqCount))

        glUniform1fv(currentFrequencies.map { GLfloat($0) }, as: guFrequencies)
        glUniform1fv((0 ..< freqCount).map { GLfloat(pow((1 - Float($0) / Float(freqCount)), 1.5) * 32) }, as: guFrequencyDistortionShiftSizes)

        let colors = (0 ..< freqCount).map {
            NSColor(hue: (CGFloat($0) / CGFloat(freqCount - 1) * 0.8 + CGFloat(time * 0.02321)).truncatingRemainder(dividingBy: 1), saturation: 1.0, brightness: 0.5, alpha: 1)
        }
        glUniform1fv(colors.flatMap { [Float($0.redComponent), Float($0.greenComponent), Float($0.blueComponent)] }, as: guFrequencyColors)
    }
}
