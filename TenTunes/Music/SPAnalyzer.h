//
//  SuperpoweredAnalyzer.h
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPAnalyzer : NSObject

- (void)analyze:(NSURL *)url;

- (unsigned char *)lowWaveform;
- (unsigned char *)midWaveform;
- (unsigned char *)highWaveform;
- (int)waveformSize;

@end

