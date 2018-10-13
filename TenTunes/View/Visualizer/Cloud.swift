//
//  Cloud.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 13.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Cloud: VisualizerView {
    var shader = ColorShader()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        compile(shader: shader, vertexResource: "visualizer", fragmentResource: "visualizer")
        Shader.unbind()
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
        
        // Draw Colors to Framebuffer
        shader.bind()
        uploadUniforms()
        drawFullScreenRect()
        
        Shader.unbind()
        
        RFOpenGLView.checkGLError("Render Error")
    }
}
