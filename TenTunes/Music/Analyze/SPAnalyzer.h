//
//  SuperpoweredAnalyzer.h
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPAnalyzer : NSObject

- (void)analyze:(NSURL *)url progressHandler: (void(^)(float, float*, int))progressHandler;

@property float progress;

@property unsigned char *averageWaveform;
@property unsigned char *lowWaveform;
@property unsigned char *midWaveform;
@property unsigned char *highWaveform;

@property unsigned char *peakWaveform;
@property unsigned char *notes;
@property char *overviewWaveform;

@property int waveformSize;

@property int overviewSize;
@property NSString *initialKey;

@property float loudpartsAverageDecibel;
@property float peakDecibel;
@property float averageDecibel;

@property float bpm;
@property float beatgridStartMs;

@end

