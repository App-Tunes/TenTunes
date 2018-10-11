//
//  RFOpenGLView.m
//
//  Created by Ross Franklin on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RFOpenGLView.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

@implementation RFOpenGLView

@synthesize deltaTime = _deltaTime;

- (CVReturn)getFrameForTime:(const CVTimeStamp *)outputTime {
    double deltaTime = 1.0 / (outputTime->rateScalar * (double)outputTime->videoTimeScale / (double)outputTime->videoRefreshPeriod);
    _deltaTime = deltaTime;
    
    [self animate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay: YES];
    });

    return kCVReturnSuccess;
}

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext) {
    @autoreleasepool {
        return [(__bridge RFOpenGLView *)displayLinkContext getFrameForTime:outputTime];
    }
}

- (void)updateDisplayLink {
    BOOL wantsLink = [self wantsDisplayLink];
    if (wantsLink == CVDisplayLinkIsRunning(_displayLink)) { return; }
    
    // TODO Update linked screen if need be
    if (!wantsLink) {
        CVDisplayLinkStop(_displayLink);
    }
    else {
        CVDisplayLinkStart(_displayLink);
    }
}

- (BOOL)wantsDisplayLink {
    return ([[self window] occlusionState] & NSWindowOcclusionStateVisible) != 0
    // Eh... It's close enough of a check
    && [self visibleRect].size.width != NSZeroRect.size.width
    && _overrideTextureID < 0;
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[self window]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDisplayLink) name:NSWindowDidChangeOcclusionStateNotification object:newWindow];
}

- (void)viewDidHide {
    [self updateDisplayLink];
}

- (void)viewDidUnhide {
    [self updateDisplayLink];
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
    
    /////
    
    _overrideTextureID = -2;
    
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    // Upload vertices
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
    
    [self createDisplayLink];

    /////
    
    if ((error = glGetError()) != 0) { NSLog(@"Setup GL Error: %d", error); }
}

- (void)createDisplayLink {
    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    
    CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink, cglContext, cglPixelFormat);
    CVDisplayLinkSetOutputCallback(_displayLink, &DisplayLinkCallback, (__bridge void *)self);
}

- (void)dealloc {
    CVDisplayLinkStop(_displayLink);
    CVDisplayLinkRelease(_displayLink);
}

- (void)animate {
    // Animate
}

- (void)prepareOpenGL {
    if ([self lockFocusIfCanDraw]) {
        [[self openGLContext] makeCurrentContext];
        CGLLockContext([[self openGLContext] CGLContextObj]);
        
        [[self openGLContext] update];
        
        CGLUnlockContext([[self openGLContext] CGLContextObj]);
        [self unlockFocus];
    }
    
    [self updateDisplayLink];
}

- (void)reshape {
    if ([self lockFocusIfCanDraw]) {
        [[self openGLContext] makeCurrentContext];
        CGLLockContext([[self openGLContext] CGLContextObj]);
        
        [[self openGLContext] update];
        
        CGLUnlockContext([[self openGLContext] CGLContextObj]);
        [self unlockFocus];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    if ([self lockFocusIfCanDraw]) {
        [[self openGLContext] makeCurrentContext];
        CGLLockContext([[self openGLContext] CGLContextObj]);
        
        if (_overrideTextureID >= 0) {
            glEnable(GL_TEXTURE_RECTANGLE);
            glBindTexture(GL_TEXTURE_RECTANGLE, _overrideTextureID);
            
            [self drawFullScreenRect];
            
            glBindTexture(GL_TEXTURE_RECTANGLE, 0);
            glDisable(GL_TEXTURE_RECTANGLE);
        }
        // -1 is special case for "don't draw at all"
        else if (_overrideTextureID < -1) {
            [self drawFrame];
        }
        
        [[self openGLContext] flushBuffer];
        
        CGLUnlockContext([[self openGLContext] CGLContextObj]);
        [self unlockFocus];
    }
}

- (void)drawFrame {
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)drawFullScreenRect {
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

+ (BOOL)checkCompiled:(GLuint)obj {
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

+ (BOOL)checkLinked:(GLuint)obj {
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

@end
