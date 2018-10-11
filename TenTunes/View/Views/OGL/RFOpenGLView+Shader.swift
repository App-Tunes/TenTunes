//
//  RFOpenGLView+Shader.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import OpenGL

extension RFOpenGLView {
    class Shader {
        var programID: GLuint? = nil

        @discardableResult
        func bind() -> Bool {
            guard let programID = programID else {
                return false
            }
            
            glUseProgram(programID)
            
            return true
        }
        
        @discardableResult
        func compile(vertex: String, fragment: String) -> Bool {
            var vss = (vertex as NSString).utf8String
            var fss = (fragment as NSString).utf8String
            
            var vs = glCreateShader(GLenum(GL_VERTEX_SHADER))
            glShaderSource(vs, 1, &vss, nil)
            glCompileShader(vs)
            
            guard RFOpenGLView.checkCompiled(vs) else {
                return false
            }
            defer { glDeleteShader(vs) }
            
            var fs = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
            glShaderSource(fs, 1, &fss, nil)
            glCompileShader(fs)
            
            guard RFOpenGLView.checkCompiled(fs) else {
                return false
            }
            defer { glDeleteShader(fs) }
            
            let programID = glCreateProgram()
            self.programID = programID
            glAttachShader(programID, vs)
            glAttachShader(programID, fs)
            glLinkProgram(programID)
            
            guard RFOpenGLView.checkGLError("Shader Link Error"), RFOpenGLView.checkLinked(programID) else {
                return false
            }
            
            return true
        }
        
        func find(uniform: String) -> Uniform {
            return Uniform(rawValue: glGetUniformLocation(programID!, uniform.cString(using: .ascii)))
        }

        func find(attribute: String) -> Attribute {
            return Attribute(rawValue: glGetAttribLocation(programID!, attribute.cString(using: .ascii)))
        }
    }
}

extension RFOpenGLView.Shader {
    class Uniform: RawRepresentable {
        typealias RawValue = GLint
        
        static let none = Uniform(rawValue: -1)
        var rawValue: RawValue
        
        required init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        func glUniform1fv(_ array: [GLfloat]) {
            array.map { GLfloat($0) }.withUnsafeBufferPointer {
                OpenGL.glUniform1fv(rawValue, GLsizei(array.count), $0.baseAddress)
            }
        }
    }
    
    class Attribute: RawRepresentable {
        typealias RawValue = GLint
        
        static let none = Attribute(rawValue: -1)
        var rawValue: RawValue
        
        required init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
}
