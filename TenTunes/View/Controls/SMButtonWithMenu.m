//
//  SMButtonWithMenu.m
//  Simplicity
//
//  Created by Evgeny Baskakov on 10/8/16.
//  Copyright © 2016 Evgeny Baskakov. All rights reserved.
//

#import "SMButtonWithMenu.h"

@implementation SMButtonWithMenu {
    NSTimer *_timer;
    BOOL _menuShown;
    BOOL _showTriangle;
}

- (void)awakeFromNib {
    [self addTrackingArea: [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self userInfo:nil]];
    
    [self setHoverImage:[NSImage imageNamed:@"caret-down"]];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    int triangleWidth = 11, triangleHeight = triangleWidth;
    int width = [self bounds].size.width, height = [self bounds].size.height;
    int margin = 0;
    
    [(_showTriangle ? _hoverImage : _idleImage) drawInRect:NSMakeRect(width - triangleWidth - margin, height - triangleHeight - margin, triangleWidth, triangleHeight)];
}

//- (void)rightMouseDown:(NSEvent *)event {
//    [self showContextMenu];
//}

- (void)mouseDown:(NSEvent *)theEvent {
    [self setHighlighted:YES];
    [self setNeedsDisplay:YES];
    
    _menuShown = NO;
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(showContextMenu:) userInfo:nil repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSEventTrackingRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}

- (void)mouseUp:(NSEvent *)theEvent {
    [self setHighlighted:NO];
    [self setNeedsDisplay:YES];
    
    [_timer invalidate];
    _timer = nil;
    
    if(!_menuShown) {
        [NSApp sendAction:[self action] to:[self target] from:self];
    }
    
    _menuShown = NO;
}

- (void)showContextMenu:(NSTimer*)timer {
    if(!_timer) {
        return;
    }
    
    [self showContextMenu];
}

- (void)showContextMenu {
    _timer = nil;
    _menuShown = YES;
    
    [_holdMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(self.bounds.size.width-8, self.bounds.size.height-1) inView:self];
    
	[self setState: NSControlStateValueOn];
}

- (void)mouseEntered:(NSEvent *)event {
    _showTriangle = true;
    [self setNeedsDisplay:true];
}

- (void)mouseExited:(NSEvent *)event {
    _showTriangle = false;
    [self setNeedsDisplay:true];
}

@end
