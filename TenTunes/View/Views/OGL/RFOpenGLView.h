//
//  RFOpenGLView.h
//
//  Created by Ross Franklin on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <OpenGL/OpenGL.h>

@interface RFOpenGLView : NSOpenGLView {
@private
    CVDisplayLinkRef _displayLink;
    CFTimeInterval _deltaTime;
    
    GLuint vertexArrayObject;
    GLuint vertexBuffer;
}

@property (readonly) CFTimeInterval deltaTime;
@property GLint overrideTextureID;

- (void)setUpOpenGL;

- (void)updateDisplayLink;
- (BOOL)wantsDisplayLink;

- (void)animate;

- (void)drawFrame;

- (void)drawFullScreenRect;

+ (BOOL)checkGLError:(NSString *)description;
+ (BOOL)checkCompiled:(GLuint)obj;
+ (BOOL)checkLinked:(GLuint)obj;

@end
