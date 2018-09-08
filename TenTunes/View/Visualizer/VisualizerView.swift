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
    var guFrequencyColorsSoon: GLint = -1
    var guFreqCount: GLint = -1
    
    var guTime: GLint = -1
    
    var startDate = NSDate().addingTimeInterval(-TimeInterval(arc4random_uniform(10_000) + 50))

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
            let middle = Double(end - 1 - start)
            let length = Double(end - start)
            return fft[start ..< end].enumerated().map { (idx, val) in
                // Frequencies that are farther away shall not be picked up as strongly
                // Multiply since this diminishes the carefully balanced values a bit
                let steepness = 4.0
                let gain = 1 / pow(0.5, steepness)
                return val / (1 + pow((Double(idx) - middle) / length, steepness) * gain) * 1.5
                }.reduce(0, +)
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
        guFrequencyColorsSoon = findUniform("frequencyColorsSoon")
        guFreqCount = findUniform("freqCount")
        
        guTime = findUniform("time")
    }
    
    func color(_ ratio: CGFloat, time: Double) -> NSColor {
        // 0.6 so that extremely high and low sounds are far apart in color
        return NSColor(hue: (ratio * 0.6 + CGFloat(time * 0.02321)).truncatingRemainder(dividingBy: 1), saturation: 1.0, brightness: 0.5, alpha: 1)
    }
    
    func rgb(_ color: NSColor) -> [Float] {
        return [Float(color.redComponent), Float(color.greenComponent), Float(color.blueComponent)]
    }
    
    override func uploadUniforms() {
        let freqCount = currentFrequencies.count
        
        let time = -startDate.timeIntervalSinceNow
        glUniform1f(guTime, GLfloat(time));
        glUniform2f(guResolution, GLfloat(bounds.size.width), GLfloat(bounds.size.height));

        glUniform1i(guFreqCount, GLint(freqCount))

        glUniform1fv(currentFrequencies.map { GLfloat($0) }, as: guFrequencies)
        glUniform1fv((0 ..< freqCount).map { GLfloat(pow((1 - Float($0) / Float(freqCount)), 1.5) * 32) }, as: guFrequencyDistortionShiftSizes)

        let colors = (0 ..< freqCount).map { self.color(CGFloat($0) / CGFloat(freqCount - 1), time: time) }
        glUniform1fv(colors.flatMap { self.rgb($0) }, as: guFrequencyColors)

        let soonColors = (0 ..< freqCount).map { self.color(CGFloat($0) / CGFloat(freqCount - 1), time: time - 50) }
        glUniform1fv(soonColors.flatMap { self.rgb($0) }, as: guFrequencyColorsSoon)
    }
}
