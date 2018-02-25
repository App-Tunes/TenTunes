//
//  SuperpoweredAnalyzer.m
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

#import "SPAnalyzer.h"

#include "SuperpoweredDecoder.h"
#include "SuperpoweredSimple.h"
#include "SuperpoweredRecorder.h"
#include "SuperpoweredTimeStretching.h"
#include "SuperpoweredAudioBuffers.h"
#include "SuperpoweredFilter.h"
#include "SuperpoweredAnalyzer.h"

@implementation SPAnalyzer {
    float progress;

    unsigned char *averageWaveform, *lowWaveform, *midWaveform, *highWaveform, *peakWaveform, *notes;
    int waveformSize, overviewSize, keyIndex;
    char *overviewWaveform;
    float loudpartsAverageDecibel, peakDecibel, bpm, averageDecibel, beatgridStartMs;
}

- (void)dealloc
{
    if (averageWaveform) free(averageWaveform);
    if (lowWaveform) free(lowWaveform);
    if (midWaveform) free(midWaveform);
    if (highWaveform) free(highWaveform);
    if (peakWaveform) free(peakWaveform);
    if (notes) free(notes);
    if (overviewWaveform) free(overviewWaveform);
}

- (unsigned char *)waveform {
    return averageWaveform;
}

- (unsigned char *)lowWaveform {
    return lowWaveform;
}

- (unsigned char *)midWaveform {
    return midWaveform;
}

- (unsigned char *)highWaveform {
    return highWaveform;
}

- (int)waveformSize {
    return waveformSize;
}

- (void)analyze:(NSURL *)url progressHandler: (void(^)(float))progressHandler {
    // Open the input file.
    SuperpoweredDecoder *decoder = new SuperpoweredDecoder();
    const char *openError = decoder->open([url fileSystemRepresentation], false, 0, 0);
    if (openError) {
        NSLog(@"open error: %s", openError);
        delete decoder;
        return;
    };
    
    // Create the analyzer.
    SuperpoweredOfflineAnalyzer *analyzer = new SuperpoweredOfflineAnalyzer(decoder->samplerate, 0, decoder->durationSeconds);
    
    // Create a buffer for the 16-bit integer samples coming from the decoder.
    short int *intBuffer = (short int *)malloc(decoder->samplesPerFrame * 2 * sizeof(short int) + 32768);
    // Create a buffer for the 32-bit floating point samples required by the effect.
    float *floatBuffer = (float *)malloc(decoder->samplesPerFrame * 2 * sizeof(float) + 32768);
    
    // Processing.
    while (true) {
        // Decode one frame. samplesDecoded will be overwritten with the actual decoded number of samples.
        unsigned int samplesDecoded = decoder->samplesPerFrame;
        if (decoder->decode(intBuffer, &samplesDecoded) == SUPERPOWEREDDECODER_ERROR) break;
        if (samplesDecoded < 1) break;
        
        // Convert the decoded PCM samples from 16-bit integer to 32-bit floating point.
        SuperpoweredShortIntToFloat(intBuffer, floatBuffer, samplesDecoded);
        
        // Submit samples to the analyzer.
        analyzer->process(floatBuffer, samplesDecoded);
        
        // Update the progress indicator.
        progress = (double)decoder->samplePosition / (double)decoder->durationSamples;
        progressHandler(progress);
    };
    
    // Get the result.
    analyzer->getresults(&averageWaveform, &peakWaveform, &lowWaveform, &midWaveform, &highWaveform, &notes, &waveformSize, &overviewWaveform, &overviewSize, &averageDecibel, &loudpartsAverageDecibel, &peakDecibel, &bpm, &beatgridStartMs, &keyIndex);
    
    // Cleanup.
    delete decoder;
    delete analyzer;
    free(intBuffer);
    free(floatBuffer);
}

@end
