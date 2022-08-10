//
//  TestMixer.h
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.08.22.
//  Copyright © 2022 ivorius. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

// Adapted from https://stackoverflow.com/questions/48059405/how-should-an-aumatrixmixer-be-configured-in-an-avaudioengine-graph
@interface AUMatrixMixerFactory : NSObject

+ (void) instantiateWithEngine: (AVAudioEngine *)_engine completionHandler:(void (^)(AVAudioUnit *))completionHandler;
+ (void)postPlaySetup: (AVAudioUnit *)unit;
	
@end

NS_ASSUME_NONNULL_END
