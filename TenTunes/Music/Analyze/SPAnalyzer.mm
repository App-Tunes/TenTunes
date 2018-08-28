//
//  SuperpoweredAnalyzer.m
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

#import "SPAnalyzer.h"

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdocumentation-deprecated-sync"
#pragma GCC diagnostic ignored "-Wdocumentation"

#include "SuperpoweredDecoder.h"
#include "SuperpoweredSimple.h"
#include "SuperpoweredRecorder.h"
#include "SuperpoweredTimeStretching.h"
#include "SuperpoweredAudioBuffers.h"
#include "SuperpoweredFilter.h"
#include "SuperpoweredAnalyzer.h"

#pragma GCC diagnostic pop

@implementation SPAnalyzer

- (void)dealloc
{
    if (_averageWaveform) free(_averageWaveform);
    if (_lowWaveform) free(_lowWaveform);
    if (_midWaveform) free(_midWaveform);
    if (_highWaveform) free(_highWaveform);
    if (_peakWaveform) free(_peakWaveform);
    if (_notes) free(_notes);
    if (_overviewWaveform) free(_overviewWaveform);
}

- (void)analyze:(NSURL *)url progressHandler: (void(^)(float, float*, int))progressHandler {
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
        _progress = (double)decoder->samplePosition / (double)decoder->durationSamples;
        progressHandler(_progress, floatBuffer, (int)samplesDecoded);
    };
    
    // Get the result.
    analyzer->getresults(&_averageWaveform, &_peakWaveform, &_lowWaveform, &_midWaveform, &_highWaveform, &_notes, &_waveformSize, &_overviewWaveform, &_overviewSize, &_averageDecibel, &_loudpartsAverageDecibel, &_peakDecibel, &_bpm, &_beatgridStartMs, &_keyIndex);
    
    // Cleanup.
    delete decoder;
    delete analyzer;
    free(intBuffer);
    free(floatBuffer);
}

@end
