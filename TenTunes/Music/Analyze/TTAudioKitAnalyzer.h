//
//  TTAudioKitAnalyzer.h
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.08.20.
//  Copyright © 2020 ivorius. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTAudioKitAnalyzer : NSObject

- (void)analyze:(NSURL *)url progressHandler: (void(^)(float, float*, int))progressHandler;

@property float progress;
@property bool failed;

@property unsigned char *averageWaveform;
@property unsigned char *lowWaveform;
@property unsigned char *midWaveform;
@property unsigned char *highWaveform;

@property int waveformSize;

@property NSString *initialKey;

@property float loudpartsAverageDecibel;
@property float peakDecibel;
@property float averageDecibel;

@property float bpm;

@end


NS_ASSUME_NONNULL_END
