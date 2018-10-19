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

class VisualizerView: SyphonableOpenGLView {
    typealias Number = Float
    
    static let skipFrequencies = 4
    static let resonanceSteepness = 15.0
    
    @objc @IBOutlet
    var delegate: VisualizerViewDelegate?
    
    var resonance: [Number] = []
    var totalResonance: Number = 0
    var highResonance: Number = 0
    
    var startDate = NSDate().addingTimeInterval(-TimeInterval(Int.random(in: 50...10_000)))
    var time : Number { return Number(-startDate.timeIntervalSinceNow) }
        
    // Settings
    @objc var colorVariance: Number = 0.3
    @objc var brightness: Number = 0.7
    @objc var psychedelic: Number = 0.3
    @objc var details: Number = 0.5

    var distortionRands = (0 ..< 100).map { _ in Number.random(in: 0 ..< 1 ) }
    
    func update(withFFT fft: [Number]) {
        let desiredLength = min(Int(details * 6 + 4), 10)
        if resonance.count != desiredLength {
            resonance = Array(repeating: 0, count: desiredLength)
        }
        
        // TODO Add Gravity so that any particular resonance can't stay high for long so we get more dynamic movement (like how ears adjust to fucking noise fuck I'm a genius)
        let desired: [Number] = (0 ..< resonance.count).map { idx in
            let middle = (pow(2.0, Number(idx)) - 1) / pow(2, Number(resonance.count)) * Number(fft.count - VisualizerView.skipFrequencies) + Number(VisualizerView.skipFrequencies)

            // Old method
            let steepness: Number = 4.0
            let gain = pow(0.5, -steepness)

            return fft.enumerated().map { (idx, val) in
                // Later frequencies stretch across more values
                let stretch = 1 + Number(idx) / 2
                // Frequencies that are farther away shall not be picked up as strongly
                let dist = abs(Number(idx) - middle)
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
        
        resonance = Interpolation.linear(resonance, desired, amount: 0.15)
        totalResonance = Interpolation.linear(totalResonance, fft.reduce(0, +) / Number(fft.count) * 650, amount: 0.15)
        let highFFT = fft.enumerated().map { (idx, val) in val * pow(Number(idx) / Number(fft.count), 3) }
        highResonance = Interpolation.linear(totalResonance, highFFT.reduce(0, +) / Number(highFFT.count) * 900, amount: 0.15)
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
        
    override func animate() {
        delegate?.visualizerViewUpdate(self)
    }
    
    func color(_ idx: Int, time: Number, darknessBonus: Number = 0) -> NSColor {
        let prog = Number(idx) / Number(resonance.count - 1)
        let ratio = resonance[idx] / totalResonance
        
        let localDarkness = pow(2, ((1 - brightness) * (darknessBonus * 2 + 1)) + 0.4)
        let brightnessBoost = pow(0.5, ((1 - ratio) * 0.4 + 0.4) / (highResonance / 15 + 1)) + ratio * 0.2
        let desaturationBoost = (0.5 + prog * 0.5) * totalResonance / 60 + prog * 0.6

        // 0.6 so that extremely high and low sounds are far apart in color
        return NSColor(hue: CGFloat(prog * colorVariance + (time * 0.02321)).truncatingRemainder(dividingBy: 1),
                       saturation: CGFloat(max(0, min(1, 0.2 + ratio * 4 * (0.8 + colorVariance) - desaturationBoost))),
                       brightness: CGFloat(min(1, resonance[idx] * 2 + brightnessBoost * 0.4) / localDarkness + 0.4),
                       alpha: 1)
    }
    
    func rgb(_ color: NSColor) -> [Number] {
        return [Number(color.redComponent), Number(color.greenComponent), Number(color.blueComponent)]
    }
    
    func uploadDefaultUniforms(onto shader: Shared) {
        glUniform1f(shader.guTime.rawValue, time);
        glUniform2f(shader.guResolution.rawValue, GLfloat(bounds.size.width), GLfloat(bounds.size.height));
    }
}
