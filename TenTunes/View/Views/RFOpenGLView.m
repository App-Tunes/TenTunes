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
    [self drawRect:_bounds];

    return kCVReturnSuccess;
}

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext) {
    @autoreleasepool {
        return [(__bridge RFOpenGLView *)displayLinkContext getFrameForTime:outputTime];
    }
}

- (void)updateDisplayLink {
    // Eh... It's close enough of a check
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
    return ([[self window] occlusionState] & NSWindowOcclusionStateVisible) != 0 &&
        [self visibleRect].size.width != NSZeroRect.size.width;
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

- (void)awakeFromNib {
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];

    [self createDisplayLink];
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
        
        [self drawFrame];
        [[self openGLContext] flushBuffer];
        
        CGLUnlockContext([[self openGLContext] CGLContextObj]);
        [self unlockFocus];
    }
}

- (void)drawFrame {
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

@end
