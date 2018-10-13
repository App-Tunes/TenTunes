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

class VisualizerView: RFOpenGLView {
    static let skipFrequencies = 4
    static let resonanceSteepness = 15.0
    
    @objc @IBOutlet
    var delegate: VisualizerViewDelegate?
    
    var resonance: [CGFloat] = []
    var totalResonance: CGFloat = 0
    var highResonance: CGFloat = 0
    
    var defaultShader = DefaultShader()
    var shader = ColorShader()
    var bloom = BloomShader()
    var bloomState = PingPongFramebuffer()
    var pingPong = PingPongFramebuffer()

    var startDate = NSDate().addingTimeInterval(-TimeInterval(Int.random(in: 50...10_000)))
    var time : TimeInterval { return -startDate.timeIntervalSinceNow }
    
    // Settings
    @objc var colorVariance: CGFloat = 0.3
    @objc var brightness: Float = 0.7
    @objc var psychedelic: CGFloat = 0.3
    @objc var details: CGFloat = 0.5

    var distortionRands = (0 ..< 100).map { _ in Float.random(in: 0 ..< 1 ) }
    
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
    
    @discardableResult
    func compile(shader: Shader, vertexResource: String, fragmentResource: String) -> Bool {
        do {
            try shader.compile(vertexResource: vertexResource, fragmentResource: fragmentResource)
        }
        catch Shader.CompileFailure.load {
            print("Failed to load shaders: \(vertexResource) . \(fragmentResource)")
            return false
        }
        catch Shader.CompileFailure.vertexCompile {
            print("Failed to compile vertex shader: \(vertexResource)")
            return false
        }
        catch Shader.CompileFailure.fragmentCompile {
            print("Failed to compile fragment shader: \(fragmentResource)")
            return false
        }
        catch {
            print("Failed to \(error) shaders: \(vertexResource) . \(fragmentResource)")
            return false
        }

        return true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        compile(shader: defaultShader, vertexResource: "default", fragmentResource: "default")
        compile(shader: shader, vertexResource: "visualizer", fragmentResource: "visualizer")
        compile(shader: bloom, vertexResource: "bloom", fragmentResource: "bloom")

        pingPong.size = bounds.size
        pingPong.create()
        
        bloomState.size = bounds.size
        bloomState.create()
        
        Framebuffer.unbind()
        Shader.unbind()
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
    
    func uploadDefaultUniforms(onto shader: Shared) {
        glUniform1f(shader.guTime.rawValue, GLfloat(time));
        glUniform2f(shader.guResolution.rawValue, GLfloat(bounds.size.width), GLfloat(bounds.size.height));
    }
    
    func uploadUniforms() {
        uploadDefaultUniforms(onto: shader)
        
        // Darkness makes points minimum smaller while loudness makes them larger
        glUniform1f(shader.guMinDist.rawValue, GLfloat(0.1 / (2 + CGFloat(1 - brightness) * 10 + totalResonance / 20)));
        // Darkness keeps points smaller while psychedelic makes them larger
        glUniform1f(shader.guDecay.rawValue, pow(1.5, (2 - brightness - Float(psychedelic)) * 5.7));
        // Brightness makes points fuzzy
        glUniform1f(shader.guSharpness.rawValue, pow(2, 1 - brightness) * 2.5);
        // More psychedelic means we zoom in more because otherwise it gets too "detailed"
        glUniform1f(shader.guScale.rawValue, pow(1300 - GLfloat(psychedelic) * 1000, (GLfloat(details) - 0.5) * 0.5 + 1) / 3000);
        // Darkness makes it less bright
        glUniform1f(shader.guBrightness.rawValue, 1.4 - (1 - brightness) * 1.35);

        glUniform1f(shader.guSpaceDistortion.rawValue, GLfloat(pow(psychedelic, 2)));

        glUniform1i(shader.guResonanceCount.rawValue, GLint(resonance.count))

        shader.guResonance.glUniform1fv(resonance.map { GLfloat($0) })
        shader.guResonanceDistortionSpeed.glUniform1fv((0 ..< resonance.count).map { GLfloat(distortionRands[$0]) })
        // Distortion Calculations
        shader.guResonanceDistortion.glUniform1fv(resonance.enumerated().map { arg in
            let (idx, res) = arg
            return GLfloat(
                // Distortion dependent on resonance
                0.357 * pow(psychedelic, 3) * (pow(1.446 - psychedelic * 0.32, CGFloat(res)) - 1)
                // High-psychedelic time dependent ambient distortion
                + (pow(psychedelic, 6) * (sin(CGFloat(time) * 0.2 / (5 + CGFloat(distortionRands[idx]))) + 1)) * 0.2
            )
        })

        // The higher the tone, the sharper its distortion
        shader.guResonanceDistortionShiftSizes.glUniform1fv((0 ..< resonance.count).map {
            GLfloat(pow((1 - Float($0) / Float(resonance.count)), 1.7) * 0.01666)
        })

        let colors = (0 ..< resonance.count).map { self.color($0, time: time) }
        shader.guResonanceColors.glUniform1fv(colors.flatMap { self.rgb($0) })

        // Outer colors can be darker if darkness is high
        let soonColors = (0 ..< resonance.count).map { self.color($0, time: time - Double(15 * colorVariance), darknessBonus: 1 - brightness) }
        shader.guResonanceColorsSoon.glUniform1fv(soonColors.flatMap { self.rgb($0) })
    }
    
    override func drawFrame() {
        super.drawFrame()
        
        pingPong.size = bounds.size
        pingPong.start()

        bloomState.size = bounds.size

        // Draw Colors to Framebuffer
        shader.bind()
        uploadUniforms()
        drawFullScreenRect()

        pingPong.end(rebind: true)

//        // Draw to Bloom Framebuffer
        bloom.bind()
        glUniform1i(bloom.guBloomImage.rawValue, 1)

        DynamicTexture.active(1) { bloomState.switch() }

        glUniform2f(bloom.guDirVec.rawValue, 0.01, 0)
        glUniform1f(bloom.guRetainer.rawValue, 0.4)
        glUniform1f(bloom.guAdder.rawValue, 0.01)
        drawFullScreenRect()

        DynamicTexture.active(1) { bloomState.switch() }

        glUniform2f(bloom.guDirVec.rawValue, 0, 0.01)
        glUniform1f(bloom.guRetainer.rawValue, 1)
        glUniform1f(bloom.guAdder.rawValue, 0)
        drawFullScreenRect()

        Framebuffer.unbind()
        
        // Draw original image to screen
        defaultShader.bind()
        drawFullScreenRect()

        // Draw bloom image to screen
        bloomState.end(rebind: true)

        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE));
        glColor4f(1, 1, 1, 0.3)
        drawFullScreenRect()
        glColor4f(1, 1, 1, 1)
        glDisable(GLenum(GL_BLEND))

        bloomState.end()
        Shader.unbind()

        RFOpenGLView.checkGLError("Render Error")
    }
}
