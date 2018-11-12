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
    
    override func setUpOpenGL() {
        super.setUpOpenGL()
        
        compile(shader: shader, vertexResource: "visualizer", fragmentResource: "visualizer")
        Shader.unbind()
    }
    
    func uploadUniforms() {
        uploadDefaultUniforms(onto: shader)
        
        // Darkness makes points minimum smaller while loudness makes them larger
        glUniform1f(shader.guMinDist, 0.1 / (2 + (1 - brightness) * 10 + totalResonance / 20))
        // Darkness keeps points smaller while psychedelic makes them larger
        glUniform1f(shader.guDecay, pow(1.5, (2.5 - brightness - psychedelic - frantic) * 5.7))
        // Brightness makes points fuzzy
        glUniform1f(shader.guSharpness, pow(2, 1 - brightness) * 2.5)
        // More psychedelic means we zoom in more because otherwise it gets too "detailed"
        glUniform1f(shader.guScale, pow(1300 - psychedelic * 1000, (details - 0.5) * 0.5 + 1) / 3000)
        // Darkness makes it less bright
        glUniform1f(shader.guBrightness, 1.4 - (1 - brightness) * 1.35)
        
        glUniform1f(shader.guSpaceDistortion, pow(psychedelic, 2) / 10)
        
        glUniform1i(shader.guResonanceCount, GLint(resonance.count))
        
        glUniform1fv(shader.guResonance, resonance)
        glUniform1fv(shader.guResonanceDistortionSpeed, (0 ..< resonance.count).map { distortionRands[$0] })
        // Distortion Calculations
        glUniform1fv(shader.guResonanceDistortion, resonance.enumerated().map { arg in
            let (idx, res) = arg
            // Distortion dependent on resonance
            return 0.357 * pow(psychedelic, 3) * (pow(1.446 - psychedelic * 0.32, res) - 1)
                    // High-psychedelic time dependent ambient distortion
                    + (pow(psychedelic, 6) * (sin(time * 0.2 / (5 + distortionRands[idx])) + 1)) * 0.2
        })
        
        // The higher the tone, the sharper its distortion
        glUniform1fv(shader.guResonanceDistortionShiftSizes, (0 ..< resonance.count).map {
            pow((1 - Number($0) / Number(resonance.count)), 1.7) * 0.01666
        })
        
        let colors = (0 ..< resonance.count).map { self.color($0, time: time) }
        glUniform1fv(shader.guResonanceColors, colors.flatMap { self.rgb($0) })
        
        // Outer colors can be darker if darkness is high
        let soonColors = (0 ..< resonance.count).map { self.color($0, time: time - (15 * colorVariance), darknessBonus: 1 - brightness) }
        glUniform1fv(shader.guResonanceColorsSoon, soonColors.flatMap { self.rgb($0) })
    }
    
    override func drawSyphonableFrame() {
        super.drawSyphonableFrame()

        // Draw Colors to Framebuffer
        shader.bind()
        uploadUniforms()
        drawFullScreenRect()
        
        Shader.unbind()
        
        RFOpenGLView.checkGLError("Render Error")
    }
}
