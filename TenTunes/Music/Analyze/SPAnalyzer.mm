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
}

- (void)analyze:(NSURL *)url progressHandler: (void(^)(float, float*, int))progressHandler {
    _failed = false;
    
    // Open the input file.
    auto *decoder = new Superpowered::Decoder();
    auto openError = decoder->open([url fileSystemRepresentation]);
    if (openError) {
        _failed = true;
        NSLog(@"open error: %d", openError);
        delete decoder;
        return;
    };
    
    // Create the analyzer.
    auto *analyzer = new Superpowered::Analyzer(decoder->getSamplerate(), decoder->getDurationSeconds());
    
    // Create a buffer for the 16-bit integer audio output of the decoder.
    short int *intBuffer = (short int *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(short int) + 16384);
    // Create a buffer for the 32-bit floating point audio required by the effect.
    float *floatBuffer = (float *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(float) + 16384);

    // Processing.
    while (true) {
        // Decode one frame. samplesDecoded will be overwritten with the actual decoded number of samples.
        auto framesDecoded = decoder->decodeAudio(intBuffer, decoder->getFramesPerChunk());
        if (framesDecoded < 1) {
            _failed = true;
            break;
        }
        
        // Convert the decoded PCM samples from 16-bit integer to 32-bit floating point.
        Superpowered::ShortIntToFloat(intBuffer, floatBuffer, framesDecoded);

        // Submit samples to the analyzer.
        analyzer->process(floatBuffer, framesDecoded);

        // Update the progress indicator.
        _progress = (double)decoder->getPositionFrames() / (double)decoder->getDurationFrames();
        progressHandler(_progress, floatBuffer, (int)framesDecoded);
    };
    
    if (!_failed) {
        int keyIndex;
        
        // Get the result.
        analyzer->makeResults(
                              60, 200, // Min-max BPM
                              0, 0, // Known and hint for BPM
                              false, // Make beatgrid start
                              false, // Beatgrid start hint
                              false, // Make overview waveform
                              true, // Low / Mid / High Waveforms
                              true // Key Index
                              );
        
        _lowWaveform = analyzer->lowWaveform;
        _lowWaveform = analyzer->lowWaveform;
        _midWaveform = analyzer->midWaveform;
        _highWaveform = analyzer->highWaveform;
        _averageWaveform = analyzer->averageWaveform;
        _waveformSize = analyzer->waveformSize;

        _loudpartsAverageDecibel = analyzer->loudpartsAverageDb;
        _averageDecibel = analyzer->averageDb;
        _peakDecibel = analyzer->peakDb;

        keyIndex = analyzer->keyIndex;
        _bpm = analyzer->bpm;

        _initialKey = [NSString stringWithCString:Superpowered::openkeyChordNames[keyIndex] encoding:NSASCIIStringEncoding];
    }
    
    // Cleanup.
    delete decoder;
    delete analyzer;
    free(intBuffer);
    free(floatBuffer);
}

@end
