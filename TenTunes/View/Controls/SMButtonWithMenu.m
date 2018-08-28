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
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (_showTriangle) {
        CGContextRef ref = NSGraphicsContext.currentContext.CGContext;
        
        int triangleWidth = 8;
        int triangleHeight = triangleWidth / 2 + 1;
        int width = [self bounds].size.width, height = [self bounds].size.height;
        int margin = 1;
        
        CGContextSetFillColorWithColor(ref, [NSColor labelColor].CGColor);
        
        CGContextBeginPath(ref);
        CGContextMoveToPoint(ref, width - triangleWidth / 2 - margin, height - margin);
        CGContextAddLineToPoint(ref, width - triangleWidth - margin, height - triangleHeight - margin);
        CGContextAddLineToPoint(ref, width - margin, height - triangleHeight - margin);
        CGContextAddLineToPoint(ref, width - triangleWidth / 2 - margin, height - margin);
        CGContextFillPath(ref);
    }
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
    
    NSWindow* window = [self window];
    
    NSEvent* fakeMouseUp = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp
                                              location:self.bounds.origin
                                         modifierFlags:0
                                             timestamp:[NSDate timeIntervalSinceReferenceDate]
                                          windowNumber:[window windowNumber]
                                               context:[NSGraphicsContext currentContext]
                                           eventNumber:0
                                            clickCount:1
                                              pressure:0.0];
    
    [window postEvent:fakeMouseUp atStart:YES];
    
    [self setState:NSOnState];
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
