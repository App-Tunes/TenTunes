//
//  TagLibFile.h
//  TenTunes
//
//  Created by Lukas Tenbrink on 30.08.2018.
//  Copyright © 2018 Lukas Tenbrink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface TagLibFile : NSObject

-(instancetype _Nullable)initWithURL:(NSURL* _Nonnull)url;

@property(nullable) NSString *title;

@property(nullable) NSString *artist;
@property(nullable) NSString *album;
@property(nullable) NSString *band;
@property(nullable) NSString *remixArtist;

@property(nullable) NSString *genre;

@property(nullable) NSImage *image;

@property(nullable) NSString *initialKey;
@property(nullable) NSString *bpm;

@property(nullable) NSString *comments;

@property unsigned int year;
@property unsigned int trackNumber;

-(BOOL)write:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end
