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

        class func unbind() {
            glUseProgram(0)
        }

        @discardableResult
        func bind() -> Bool {
            guard let programID = programID else {
                return false
            }
            
            glUseProgram(programID)
            
            return true
        }
        
        enum CompileFailure : Error {
            case load
            case vertexCompile, fragmentCompile
            case link
            case attribute
            case uniform
        }
        
        func compile(vertexResource: String, ofType vertexType: String = "vs", fragmentResource: String, ofType fragmentType: String = "fs") throws {
            guard let vertexPath = Bundle.main.path(forResource: vertexResource, ofType: vertexType),
                let fragmentPath = Bundle.main.path(forResource: fragmentResource, ofType: fragmentType),
                let vertex = try? String(contentsOfFile: vertexPath),
                let fragment = try? String(contentsOfFile: fragmentPath)
                else {
                    throw CompileFailure.load
            }
            
            try compile(vertex: vertex, fragment: fragment)
        }

        func compile(vertex: String, fragment: String) throws {
            var vss = (vertex as NSString).utf8String
            var fss = (fragment as NSString).utf8String
            
            var vs = glCreateShader(GLenum(GL_VERTEX_SHADER))
            glShaderSource(vs, 1, &vss, nil)
            glCompileShader(vs)
            
            guard RFOpenGLView.checkCompiled(vs) else {
                throw CompileFailure.vertexCompile
            }
            defer { glDeleteShader(vs) }
            
            var fs = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
            glShaderSource(fs, 1, &fss, nil)
            glCompileShader(fs)
            
            guard RFOpenGLView.checkCompiled(fs) else {
                throw CompileFailure.fragmentCompile
            }
            defer { glDeleteShader(fs) }
            
            let programID = glCreateProgram()
            self.programID = programID
            glAttachShader(programID, vs)
            glAttachShader(programID, fs)
            glLinkProgram(programID)
            
            guard RFOpenGLView.checkGLError("Shader Link Error"), RFOpenGLView.checkLinked(programID) else {
                throw CompileFailure.link
            }
        }
        
        func checkAttributeError() throws {
            guard RFOpenGLView.checkGLError("Attribute Error") else {
                throw CompileFailure.attribute
            }
        }

        func checkUniformError() throws {
            guard RFOpenGLView.checkGLError("Uniform Error") else {
                throw CompileFailure.uniform
            }
        }

        func find(uniform: String) -> Uniform {
            let val = glGetUniformLocation(programID!, uniform.cString(using: .ascii))
            if val < 0 { print("No such uniform: \(uniform)") }
            return Uniform(rawValue: val)
        }

        func find(attribute: String) -> Attribute {
            let val = glGetAttribLocation(programID!, attribute.cString(using: .ascii))
            if val < 0 { print("No such attribute: \(attribute)") }
            return Attribute(rawValue: val)
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
