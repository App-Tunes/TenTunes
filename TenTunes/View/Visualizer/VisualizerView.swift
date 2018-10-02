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
    var guResonanceDistortion: GLint = -1
    var guResonanceDistortionSpeed: GLint = -1
    var guResonanceDistortionShiftSizes: GLint = -1

    var guResonanceColors: GLint = -1
    var guResonanceColorsSoon: GLint = -1
    var guResonanceCount: GLint = -1
    
    var guTime: GLint = -1

    var guMinDist: GLint = -1
    var guDecay: GLint = -1
    var guSharpness: GLint = -1
    var guScale: GLint = -1
    var guBrightness: GLint = -1

    var startDate = NSDate().addingTimeInterval(-TimeInterval(Int.random(in: 50...10_000)))
    var time : TimeInterval { return -startDate.timeIntervalSinceNow }
    
    // Settings
    @objc var colorVariance: CGFloat = 0.3
    @objc var darkness: Float = 0.3
    @objc var psychedelic: CGFloat = 0.3
    
    var distortionRands = (0 ..< 100).map { _ in Float.random(in: 0 ..< 1 ) }

    func update(withFFT fft: [Double]) {
        let desiredLength = Int(log(Double(fft.count)) / log(2)) - VisualizerView.resonanceOverlap
        if resonance.count != desiredLength {
            resonance = Array(repeating: 0, count: desiredLength)
        }
        
        // TODO Add Gravity so that any particular resonance can't stay high for long so we get more dynamic movement (like how ears adjust to fucking noise fuck I'm a genius)
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
        guResonanceDistortion = findUniform("resonanceDistortion")
        guResonanceDistortionSpeed = findUniform("resonanceDistortionSpeed")
        guResonanceDistortionShiftSizes = findUniform("resonanceDistortionShiftSizes")
        
        guResonanceColors = findUniform("resonanceColors")
        guResonanceColorsSoon = findUniform("resonanceColorsSoon")
        guResonanceCount = findUniform("resonanceCount")
        
        guTime = findUniform("time")

        guMinDist = findUniform("minDist")
        guDecay = findUniform("decay")
        guSharpness = findUniform("sharpness")
        guScale = findUniform("scale")
        guBrightness = findUniform("brightness")
    }
    
    override func animate() {
        guard let fft = delegate?.visualizerViewFFTData(self) else {
            return
        }
        
        update(withFFT: fft)
    }
    
    func color(_ idx: Int, time: Double, darknessBonus: Float = 0) -> NSColor {
        let prog = CGFloat(idx) / CGFloat(resonance.count - 1)
        let ratio: CGFloat = resonance[idx] / totalResonance
        
        let localDarkness = pow(2, CGFloat(darkness * (darknessBonus * 2 + 1)) + 0.4)

        // 0.6 so that extremely high and low sounds are far apart in color
        return NSColor(hue: (prog * colorVariance + CGFloat(time * 0.02321)).truncatingRemainder(dividingBy: 1),
                       saturation: max(0, min(1, ratio * 5 - prog)),
                       brightness: min(1, totalResonance / 15 + resonance[idx] * 2 + ratio * 0.3) / localDarkness + 0.4,
                       alpha: 1)
    }
    
    func rgb(_ color: NSColor) -> [Float] {
        return [Float(color.redComponent), Float(color.greenComponent), Float(color.blueComponent)]
    }
    
    override func uploadUniforms() {
        glUniform1f(guTime, GLfloat(time));
        glUniform2f(guResolution, GLfloat(bounds.size.width), GLfloat(bounds.size.height));

        glUniform1f(guMinDist, GLfloat(0.1 / (2 + CGFloat(darkness) * 10 + totalResonance / 20)));
        glUniform1f(guDecay, pow(1.5, (1 + darkness - Float(psychedelic)) * 5.7));
        glUniform1f(guSharpness, pow(2, darkness) * 2.5);
        glUniform1f(guScale, 1300 - GLfloat(psychedelic) * 1000);
        glUniform1f(guBrightness, 1.4 - darkness * 1.35);

        glUniform1i(guResonanceCount, GLint(resonance.count))

        glUniform1fv(resonance.map { GLfloat($0) }, as: guResonance)
        glUniform1fv((0 ..< resonance.count).map { GLfloat(distortionRands[$0]) }, as: guResonanceDistortionSpeed)
        glUniform1fv(resonance.map {
            GLfloat(0.297 * pow(psychedelic, 3) * (pow(1.65 - psychedelic, CGFloat($0)) - (1.3 - psychedelic)))
        }, as: guResonanceDistortion)

        glUniform1fv((0 ..< resonance.count).map {
            GLfloat(pow((1 - Float($0) / Float(resonance.count)), 1.5) * 25)
        }, as: guResonanceDistortionShiftSizes)

        let colors = (0 ..< resonance.count).map { self.color($0, time: time) }
        glUniform1fv(colors.flatMap { self.rgb($0) }, as: guResonanceColors)

        let soonColors = (0 ..< resonance.count).map { self.color($0, time: time - Double(20 * colorVariance), darknessBonus: darkness) }
        glUniform1fv(soonColors.flatMap { self.rgb($0) }, as: guResonanceColorsSoon)
    }
}
