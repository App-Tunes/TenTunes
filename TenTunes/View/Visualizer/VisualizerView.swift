//
//  VisualizerView.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import OpenGL
import Darwin

@objc protocol VisualizerViewDelegate {
    func visualizerViewUpdate(_ view: VisualizerView)
}

class VisualizerView: GLSLView {
    static let skipFrequencies = 4
    static let resonanceSteepness = 15.0
    
    @objc @IBOutlet
    var delegate: VisualizerViewDelegate?
    
    var resonance: [CGFloat] = []
    var totalResonance: CGFloat = 0
    var highResonance: CGFloat = 0
    
    var gaPosition: Shader.Attribute = .none

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
    
//    var bloomTexture: DynamicTexture!

    var startDate = NSDate().addingTimeInterval(-TimeInterval(Int.random(in: 50...10_000)))
    var time : TimeInterval { return -startDate.timeIntervalSinceNow }
    
    // Settings
    @objc var colorVariance: CGFloat = 0.3
    @objc var brightness: Float = 0.7
    @objc var psychedelic: CGFloat = 0.3
    @objc var details: CGFloat = 0.5

    var distortionRands = (0 ..< 100).map { _ in Float.random(in: 0 ..< 1 ) }

//    override init(frame frameRect: NSRect) {
//        super.init(frame: frameRect)
//        
//        bloomTexture = DynamicTexture(for: self)
//    }
//    
//    required init?(coder decoder: NSCoder) {
//        super.init(coder: decoder)
//        
//        bloomTexture = DynamicTexture(for: self)
//    }
    
    func update(withFFT fft: [Double]) {
        let desiredLength = min(Int(details * 6 + 4), 10)
        if resonance.count != desiredLength {
            resonance = Array(repeating: 0, count: desiredLength)
        }
        
        // TODO Add Gravity so that any particular resonance can't stay high for long so we get more dynamic movement (like how ears adjust to fucking noise fuck I'm a genius)
        let desiredDoubles: [Double] = (0 ..< resonance.count).map { idx in
            let middle = (pow(2.0, Double(idx)) - 1) / pow(2, Double(resonance.count)) * Double(fft.count - VisualizerView.skipFrequencies) + Double(VisualizerView.skipFrequencies)

            // Old method
            let steepness = 4.0
            let gain = pow(0.5, -steepness)

            return fft.enumerated().map { (idx, val) in
                // Later frequencies stretch across more values
                let stretch = 1 + Double(idx) / 2
                // Frequencies that are farther away shall not be picked up as strongly
                let dist = abs(Double(idx) - middle)
                // Multiply since this diminishes the carefully balanced values a bit
                return val / (1 + pow(dist / stretch, steepness) * gain) * 2.2
                }.reduce(0, +)

//            return fft.enumerated().map { (idx, val) in
//                // Later frequencies stretch across more values
//                let variance = pow((1 + Double(idx)) / VisualizerView.resonanceSteepness, 2)
//                let scalar = pow(4.0 / VisualizerView.resonanceSteepness, 2)
//                // Frequencies that are farther away shall not be picked up as strongly
//                let dist = pow(Double(Double(idx) - middle), 2)
//                // Normal distribution
//                let resonance = 1 / sqrt(2 * Double.pi * scalar) * pow(Darwin.M_E, (-dist / (2 * variance))) * 5
//                return val * resonance
//                }.reduce(0, +)
        }
        
        let desired = desiredDoubles.map { CGFloat($0) }

        resonance = Interpolation.linear(resonance, desired, amount: 0.15)
        totalResonance = Interpolation.linear(totalResonance, CGFloat(fft.reduce(0, +) / Double(fft.count)) * 650, amount: 0.15)
        let highFFT = fft.enumerated().map { (idx, val) in val * pow(Double(idx) / Double(fft.count), 3) }
        highResonance = Interpolation.linear(totalResonance, CGFloat(highFFT.reduce(0, +) / Double(highFFT.count)) * 900, amount: 0.15)
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
        
        shader.compile(vertex: vertex, fragment: fragment)
        
        gaPosition = shader.find(attribute: "position")
        glEnableVertexAttribArray(GLuint(gaPosition.rawValue))
        glVertexAttribPointer(GLuint(gaPosition.rawValue), 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 4), nil)

        guard GLSLView.checkGLError("Attribute Error") else {
            return
        }

        guResolution = shader.find(uniform: "resolution")
        
        guResonance = shader.find(uniform: "resonance")
        guResonanceDistortion = shader.find(uniform: "resonanceDistortion")
        guResonanceDistortionSpeed = shader.find(uniform: "resonanceDistortionSpeed")
        guResonanceDistortionShiftSizes = shader.find(uniform: "resonanceDistortionShiftSizes")
        
        guResonanceColors = shader.find(uniform: "resonanceColors")
        guResonanceColorsSoon = shader.find(uniform: "resonanceColorsSoon")
        guResonanceCount = shader.find(uniform: "resonanceCount")
        
        guTime = shader.find(uniform: "time")

        guMinDist = shader.find(uniform: "minDist")
        guDecay = shader.find(uniform: "decay")
        guSharpness = shader.find(uniform: "sharpness")
        guScale = shader.find(uniform: "scale")
        guBrightness = shader.find(uniform: "brightness")

        guSpaceDistortion = shader.find(uniform: "spaceDistortion")
        
        guard GLSLView.checkGLError("Uniform Error") else {
            return
        }

//        bloomTexture.update()
    }
    
    override func animate() {
        delegate?.visualizerViewUpdate(self)
    }
    
    func color(_ idx: Int, time: Double, darknessBonus: Float = 0) -> NSColor {
        let prog = CGFloat(idx) / CGFloat(resonance.count - 1)
        let ratio: CGFloat = resonance[idx] / totalResonance
        
        let localDarkness = pow(2, CGFloat((1 - brightness) * (darknessBonus * 2 + 1)) + 0.4)

        // 0.6 so that extremely high and low sounds are far apart in color
        return NSColor(hue: (prog * colorVariance + CGFloat(time * 0.02321)).truncatingRemainder(dividingBy: 1),
                       saturation: max(0, min(1, ratio * 4 - prog - totalResonance / 40)),
                       brightness: min(1, highResonance / 15 + resonance[idx] * 2 + ratio * 0.3) / localDarkness + 0.4,
                       alpha: 1)
    }
    
    func rgb(_ color: NSColor) -> [Float] {
        return [Float(color.redComponent), Float(color.greenComponent), Float(color.blueComponent)]
    }
    
    override func uploadUniforms() {
        glUniform1f(guTime.rawValue, GLfloat(time));
        glUniform2f(guResolution.rawValue, GLfloat(bounds.size.width), GLfloat(bounds.size.height));

        // Darkness makes points minimum smaller while loudness makes them larger
        glUniform1f(guMinDist.rawValue, GLfloat(0.1 / (2 + CGFloat(1 - brightness) * 10 + totalResonance / 20)));
        // Darkness keeps points smaller while psychedelic makes them larger
        glUniform1f(guDecay.rawValue, pow(1.5, (2 - brightness - Float(psychedelic)) * 5.7));
        // Brightness makes points fuzzy
        glUniform1f(guSharpness.rawValue, pow(2, 1 - brightness) * 2.5);
        // More psychedelic means we zoom in more because otherwise it gets too "detailed"
        glUniform1f(guScale.rawValue, pow(1300 - GLfloat(psychedelic) * 1000, (GLfloat(details) - 0.5) * 0.5 + 1) / 3000);
        // Darkness makes it less bright
        glUniform1f(guBrightness.rawValue, 1.4 - (1 - brightness) * 1.35);

        glUniform1f(guSpaceDistortion.rawValue, GLfloat(pow(psychedelic, 2)));

        glUniform1i(guResonanceCount.rawValue, GLint(resonance.count))

        guResonance.glUniform1fv(resonance.map { GLfloat($0) })
        guResonanceDistortionSpeed.glUniform1fv((0 ..< resonance.count).map { GLfloat(distortionRands[$0]) })
        // Distortion Calculations
        guResonanceDistortion.glUniform1fv(resonance.enumerated().map { arg in
            let (idx, res) = arg
            return GLfloat(
                // Distortion dependent on resonance
                0.357 * pow(psychedelic, 3) * (pow(1.446 - psychedelic * 0.32, CGFloat(res)) - 1)
                // High-psychedelic time dependent ambient distortion
                + (pow(psychedelic, 6) * (sin(CGFloat(time) * 0.2 / (5 + CGFloat(distortionRands[idx]))) + 1)) * 0.2
            )
        })

        // The higher the tone, the sharper its distortion
        guResonanceDistortionShiftSizes.glUniform1fv((0 ..< resonance.count).map {
            GLfloat(pow((1 - Float($0) / Float(resonance.count)), 1.7) * 0.01666)
        })

        let colors = (0 ..< resonance.count).map { self.color($0, time: time) }
        guResonanceColors.glUniform1fv(colors.flatMap { self.rgb($0) })

        // Outer colors can be darker if darkness is high
        let soonColors = (0 ..< resonance.count).map { self.color($0, time: time - Double(15 * colorVariance), darknessBonus: 1 - brightness) }
        guResonanceColorsSoon.glUniform1fv(soonColors.flatMap { self.rgb($0) })
    }
    
//    override func drawFrame() {
//        super.drawFrame()
//        bloomTexture.size = bounds.size
//        bloomTexture.bind()
//    }
}
