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

@objc protocol VisualizerViewDelegate {
    func visualizerViewFFTData(_ view: VisualizerView) -> [Double]?
}

class VisualizerView: GLSLView {
    static let resonanceOverlap = 2
    
    @objc @IBOutlet
    var delegate: VisualizerViewDelegate?
    
    var resonance: [CGFloat] = []
    var totalResonance: CGFloat { return resonance.reduce(into: 0) { $0 = $0 + $1 } }

    var guResolution: GLint = -1

    var guResonance: GLint = -1
    var guResonanceDistortionShiftSizes: GLint = -1
    var guResonanceColors: GLint = -1
    var guResonanceColorsSoon: GLint = -1
    var guResonanceCount: GLint = -1
    
    var guTime: GLint = -1

    var guMinDist: GLint = -1
    var guDecay: GLint = -1

    var startDate = NSDate().addingTimeInterval(-TimeInterval(arc4random_uniform(10_000) + 50))
    var time : TimeInterval { return -startDate.timeIntervalSinceNow }

    func update(withFFT fft: [Double]) {
        let desiredLength = Int(log(Double(fft.count)) / log(2)) - VisualizerView.resonanceOverlap
        if resonance.count != desiredLength {
            resonance = Array(repeating: 0, count: desiredLength)
        }
        
        let desiredDoubles: [Double] = (0 ..< resonance.count).map { idx in
            let start = Int((pow(2.0, Double(idx))) - 1)
            // We do +2 so we have an overlap between similar frequencies
            let end = Int((pow(2.0, Double(idx + VisualizerView.resonanceOverlap + 1))) - 1)
            // Don't divide by size since this is how we hear it too
            let middle = Double(end - 1 - start)
            let length = Double(end - start)

            let steepness = 4.0
            let gain = 1 / pow(0.5, steepness)

            return fft[start ..< end].enumerated().map { (idx, val) in
                // Frequencies that are farther away shall not be picked up as strongly
                // Multiply since this diminishes the carefully balanced values a bit
                return val / (1 + pow(abs(Double(idx) - middle) / length, steepness) * gain) * 1.7
                }.reduce(0, +)
        }
        
        let desired = desiredDoubles.map { CGFloat($0) }

        resonance = Interpolation.linear(resonance, desired, amount: 0.15)
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
        
        guResonance = findUniform("resonance")
        guResonanceDistortionShiftSizes = findUniform("resonanceDistortionShiftSizes")
        guResonanceColors = findUniform("resonanceColors")
        guResonanceColorsSoon = findUniform("resonanceColorsSoon")
        guResonanceCount = findUniform("resonanceCount")
        
        guTime = findUniform("time")

        guMinDist = findUniform("minDist")
        guDecay = findUniform("decay")
    }
    
    override func animate() {
        guard let fft = delegate?.visualizerViewFFTData(self) else {
            return
        }
        
        update(withFFT: fft)
    }
    
    func color(_ idx: Int, time: Double) -> NSColor {
        let prog = CGFloat(idx) / CGFloat(resonance.count - 1)
        let ratio: CGFloat = resonance[idx] / totalResonance
        
        // 0.6 so that extremely high and low sounds are far apart in color
        return NSColor(hue: (prog * 0.6 + CGFloat(time * 0.02321)).truncatingRemainder(dividingBy: 1),
                       saturation: min(1, ratio * 3),
                       brightness: min(0.7, totalResonance / 3) + ratio * 0.3,
                       alpha: 1)
    }
    
    func rgb(_ color: NSColor) -> [Float] {
        return [Float(color.redComponent), Float(color.greenComponent), Float(color.blueComponent)]
    }
    
    override func uploadUniforms() {
        glUniform1f(guTime, GLfloat(time));
        glUniform2f(guResolution, GLfloat(bounds.size.width), GLfloat(bounds.size.height));

        glUniform1f(guMinDist, GLfloat(0.1 / (5 + totalResonance / 20)));
        glUniform1f(guDecay, 10);

        glUniform1i(guResonanceCount, GLint(resonance.count))

        glUniform1fv(resonance.map { GLfloat($0) }, as: guResonance)
        glUniform1fv((0 ..< resonance.count).map { GLfloat(pow((1 - Float($0) / Float(resonance.count)), 1.5) * 25) }, as: guResonanceDistortionShiftSizes)

        let colors = (0 ..< resonance.count).map { self.color($0, time: time) }
        glUniform1fv(colors.flatMap { self.rgb($0) }, as: guResonanceColors)

        let soonColors = (0 ..< resonance.count).map { self.color($0, time: time - 50) }
        glUniform1fv(soonColors.flatMap { self.rgb($0) }, as: guResonanceColorsSoon)
    }
}
