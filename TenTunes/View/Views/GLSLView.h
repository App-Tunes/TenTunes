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
    
    GLint positionUniform;
    GLint positionAttribute;

    GLint timeAttribute;
    GLint resolutionAttribute;
    GLint frequenciesAttribute;
    
    GLfloat frequenciesArray[24];
}

@property NSDate *startDate;
@property (nonatomic) NSArray *frequencies;

@end
