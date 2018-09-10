//
//  GLSLView.h
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "RFOpenGLView.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

@interface GLSLView : RFOpenGLView
{
    GLuint shaderProgram;
    GLuint vertexArrayObject;
    GLuint vertexBuffer;
    
    GLint positionAttribute;
}

- (void)compileShaders:(NSString *)vertex fragment:(NSString *)fragment;

- (GLint)findUniform:(NSString *)name;
- (void)uploadUniforms;

@end
