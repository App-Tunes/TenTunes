//
//  JUKImporter.h
//  JukeKit
//
//  Created by Thomas Günzel on 14.12.2017.
//  Copyright © 2017 Thomas Günzel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface JUKImporter : NSObject

-(instancetype)initWithURL:(NSURL*)url;

-(BOOL)import:(NSError *__autoreleasing *)error;

@property(readonly) NSURL *url;

@property NSString *title;
@property NSString *artist;
@property NSString *album;

@property NSImage *image;

@property NSString *initialKey;
@property NSString *bpm;

@end
