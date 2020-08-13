//
//  TTAudioKitAnalyzer.m
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.08.20.
//  Copyright © 2020 ivorius. All rights reserved.
//

#import "TTAudioKitAnalyzer.h"
#import <AudioKit/AudioKit.h>

@implementation TTAudioKitAnalyzer

- (void)analyze:(NSURL *)url progressHandler:(void (^)(float, float * _Nonnull, int))progressHandler {
    NSError *error;
    AKAudioFile *file = [[AKAudioFile alloc] initForReading:url error:&error];
    
    if (error) {
        _failed = true;
        NSLog(@"open error: %@", error);
        return;
    };
    if (file.length <= 0) {
        _failed = true;
        NSLog(@"no samples");
        return;
    }
    
    AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat: file.processingFormat frameCapacity: (unsigned int) file.length];
    [file readIntoBuffer:buffer error:&error];
    if (error) {
        _failed = true;
        NSLog(@"read error: %@", error);
        return;
    };

    AVAudioFrameCount frameLength = buffer.frameLength;
    unsigned int chunkBase = 11;
    unsigned int chunkSize = pow(2, chunkBase);
    _waveformSize = frameLength / chunkSize;

    /* supports up to 2048 (2**11) points  */
    FFTSetup setup = vDSP_create_fftsetup(chunkBase, kFFTRadix2);
    int outCount = chunkSize;

    float outReal[outCount];
    float outImaginary[outCount];
    COMPLEX_SPLIT output = { .realp = outReal, .imagp = outImaginary };
    
    float *avg = malloc(sizeof(float) * _waveformSize);
    memset(avg, 0, sizeof(float) * _waveformSize);
    float avgM = 255 * 100.0f / outCount / [file channelCount] / chunkSize;

    float *lows = malloc(sizeof(float) * _waveformSize);
    memset(lows, 0, sizeof(float) * _waveformSize);
    int lowS = outCount * 4 / 5;
    int lowC = outCount / 5;
    float lowM = 255 * 50.0f / lowC / [file channelCount] / chunkSize;
    
    float *mids = malloc(sizeof(float) * _waveformSize);
    memset(mids, 0, sizeof(float) * _waveformSize);
    int midS = outCount / 3;
    int midC = outCount / 3;
    float midM = 255 * 100.0f / midC / [file channelCount] / chunkSize;

    float *highs = malloc(sizeof(float) * _waveformSize);
    memset(highs, 0, sizeof(float) * _waveformSize);
    int highS = outCount / 10;
    int highC = outCount / 4;
    float highM = 255 * 200.0f / highC / [file channelCount] / chunkSize;

    _averageWaveform = malloc(sizeof(char) * _waveformSize);
    _lowWaveform = malloc(sizeof(char) * _waveformSize);
    _midWaveform = malloc(sizeof(char) * _waveformSize);
    _highWaveform = malloc(sizeof(char) * _waveformSize);

    for (int chunk = 0; chunk < _waveformSize; chunk++) {
        for (int c = 0; c < [file channelCount]; c++) {
            float *floats = buffer.floatChannelData[c];

            float *data = floats + chunk * chunkSize;

            memcpy(output.realp, data, chunkSize * sizeof(float));
            memset(output.imagp, 0, chunkSize * sizeof(float));
            
            // TODO Use vDSP_fftm_zip
            vDSP_fft_zip(setup, &output, 1, chunkBase, FFT_FORWARD);
            
            // Vector Magnitude
            vDSP_zvabs(&output, 1, output.realp, 1, outCount);

//            // Scale the FFT data
//            float fftNormFactor = 1.0 / chunkSize;
//            vDSP_vsmul(output.realp, 1, &fftNormFactor, output.realp, 1, outCount);
            
            for (int i = 0; i < outCount; i++)
                avg[chunk] += output.realp[i];
            
            for (int i = lowS; i < lowS + lowC; i++)
                lows[chunk] += output.realp[i];
            
            for (int i = midS; i < midS + midC; i++)
                mids[chunk] += output.realp[i];
            
            for (int i = highS; i < highS + highC; i++)
                highs[chunk] += output.realp[i];
        }
        
        _averageWaveform[chunk] = (unsigned char) MIN(255, avg[chunk] * avgM);
        _lowWaveform[chunk] = (unsigned char) MIN(255, lows[chunk] * lowM);
        _midWaveform[chunk] = (unsigned char) MIN(255, mids[chunk] * midM);
        _highWaveform[chunk] = (unsigned char) MIN(255, highs[chunk] * highM);
        
        _progress = (double)chunk / (double)_waveformSize;
        progressHandler(_progress, buffer.floatChannelData[0], chunkSize);
    }
    
    // Find loudparts threshold
    
    unsigned char threshold = 128;
    int minCount = _waveformSize / 40;
    int maxCount = _waveformSize / 30;
    int includedCount = 0;
    for (int try = 6; try > 1; try--) {
        includedCount = 0;
        for (int chunk = 0; chunk < _waveformSize; chunk++) {
            if (_averageWaveform[chunk] > threshold)
                includedCount ++;
        }
        
        int add = pow(2, try);
        if (includedCount < minCount)
            threshold -= add;
        else if (includedCount > maxCount)
            threshold += add;
        else
            break;
    }
    
    _loudpartsAverageDecibel = 0.0f;
    for (int chunk = 0; chunk < _waveformSize; chunk++) {
        if (_averageWaveform[chunk] > threshold)
            _loudpartsAverageDecibel += _averageWaveform[chunk];
    }
    _loudpartsAverageDecibel /= includedCount;

    vDSP_destroy_fftsetup(setup);
}

@end
