//
//  GLSLView.m
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

#import "GLSLView.h"
#import <OpenGL/glu.h>

@implementation GLSLView

+ (CFTimeInterval)timeMouseIdle
{
    return CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGEventMouseMoved);
}

- (void)awakeFromNib
{    
    int error;
    
    // 1. Create a context with opengl pixel format
    NSOpenGLPixelFormatAttribute pixelFormatAttributes[] =
    {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFAColorSize    , 24                           ,
        NSOpenGLPFAAlphaSize    , 8                            ,
        NSOpenGLPFADoubleBuffer ,
        NSOpenGLPFAAccelerated  ,
        NSOpenGLPFANoRecovery   ,
        0
    };
    if (![self isOpaque]) {
        GLint opacity = 0;
        [[self openGLContext] setValues:&opacity forParameter:NSOpenGLContextParameterSurfaceOpacity];
    }

    NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes];
    super.pixelFormat = pixelFormat;
    
    // 2. Make the context current
    [[self openGLContext] makeCurrentContext];

    [super awakeFromNib];
    
    if ((error = glGetError()) != 0) { NSLog(@"Setup GL Error: %d", error); }
    
    // 6. Upload vertices
    GLfloat vertexData[]= { -1,-1,0.0,1.0,
        -1, 1,0.0,1.0,
        1, 1,0.0,1.0,
        1,-1,0.0,1.0 }
    ;
    glGenVertexArrays(1, &vertexArrayObject);
    glBindVertexArray(vertexArrayObject);
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, 4*8*sizeof(GLfloat), vertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray((GLuint)positionAttribute);
    glVertexAttribPointer((GLuint)positionAttribute, 4, GL_FLOAT, GL_FALSE, 4*sizeof(GLfloat), 0);
    
    if ((error = glGetError()) != 0) { NSLog(@"Setup End GL Error: %d", error); }
}

- (void)compileShaders:(NSString *)vertex fragment:(NSString *)fragment {
    int error;
    
    GLuint  vs;
    GLuint  fs;
    const char *fss = [fragment cStringUsingEncoding:NSUTF8StringEncoding];
    const char *vss= [vertex cStringUsingEncoding:NSUTF8StringEncoding];
    
    vs = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vs, 1, &vss, NULL);
    glCompileShader(vs);
    if (![self checkCompiled: vs]) { return; }
    
    fs = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fs, 1, &fss, NULL);
    glCompileShader(fs);
    if (![self checkCompiled: fs]) { return; }
    
    // 4. Attach the shaders
    shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vs);
    glAttachShader(shaderProgram, fs);
    glLinkProgram(shaderProgram);
    
    if ((error = glGetError()) != 0) { NSLog(@"Shader Link GL Error: %d", error); }
    if (![self checkLinked: shaderProgram]) { return; }
    
    // 5. Get pointers to uniforms and attributes
    positionAttribute = glGetAttribLocation(shaderProgram, "position");
    
    if ((error = glGetError()) != 0) { NSLog(@"Attrib Link GL Error: %d", error); }
    
    glDeleteShader(vs);
    glDeleteShader(fs);
}

- (BOOL)checkCompiled:(GLint)obj {
    GLint isCompiled = 0;
    glGetShaderiv(obj, GL_COMPILE_STATUS, &isCompiled);
    if(isCompiled == GL_FALSE)
    {
        GLint maxLength = 0;
        glGetShaderiv(obj, GL_INFO_LOG_LENGTH, &maxLength);
        
        GLchar *log = (GLchar *)malloc(maxLength);
        glGetShaderInfoLog(obj, maxLength, &maxLength, log);
        printf("Shader Compile Error: \n%s\n", log);
        free(log);
        
        glDeleteShader(obj);
        return NO;
    }
    
    return YES;
}

- (BOOL)checkLinked:(GLint)obj {
    int maxLength = 0;
    glGetProgramiv(obj, GL_INFO_LOG_LENGTH, &maxLength);
    if (maxLength > 0)
    {
        GLchar *log = (GLchar *)malloc(maxLength);
        glGetProgramInfoLog(obj, maxLength, &maxLength, log);
        printf("Shader Program Error: \n%s\n", log);
        free(log);
        
        return NO;
    }
    
    return YES;
}

- (void)drawFrame {
    [super drawFrame];
    
    glUseProgram(shaderProgram);
    
    [self uploadUniforms];
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

- (GLint)findUniform:(NSString *)name {
    return glGetUniformLocation(shaderProgram, [name cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)uploadUniforms {
    
}

@end
