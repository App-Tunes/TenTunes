//
//  JUKImporter.h
//  JukeKit
//
//  Created by Thomas Günzel on 14.12.2017.
//  Copyright © 2017 Thomas Günzel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface TagLibImporter : NSObject

-(instancetype _Nonnull)initWithURL:(NSURL* _Nonnull)url;

-(BOOL)import:(NSError * _Nullable __autoreleasing * _Nullable)error;
-(BOOL)write:(NSError * _Nullable __autoreleasing * _Nullable)error;

@property(readonly, nonnull) NSURL *url;

@property(nullable) NSString *title;
@property(nullable) NSString *artist;
@property(nullable) NSString *album;
@property(nullable) NSString *genre;

@property(nullable) NSImage *image;

@property(nullable) NSString *initialKey;
@property(nullable) NSString *bpm;

@end
