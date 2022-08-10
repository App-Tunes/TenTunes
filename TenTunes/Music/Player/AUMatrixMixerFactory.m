//
//  TestMixer.m
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.08.22.
//  Copyright © 2022 ivorius. All rights reserved.
//

#import "AUMatrixMixerFactory.h"

@implementation AUMatrixMixerFactory

+ (void) instantiateWithEngine: (AVAudioEngine *)_engine completionHandler:(void (^)(AVAudioUnit *))completionHandler {
	AudioComponentDescription mixerDesc;
	mixerDesc.componentType = kAudioUnitType_Mixer;
	mixerDesc.componentSubType = kAudioUnitSubType_MatrixMixer;
	mixerDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
	mixerDesc.componentFlags = kAudioComponentFlag_SandboxSafe;

	[AVAudioUnit instantiateWithComponentDescription:mixerDesc options:kAudioComponentInstantiation_LoadInProcess completionHandler:^(__kindof AVAudioUnit * _Nullable mixerUnit, NSError * _Nullable error) {
		[_engine attachNode: mixerUnit];

		/*Give the mixer one input bus and one output bus*/
		UInt32 inBuses = 1;
		UInt32 outBuses = 1;
		AudioUnitSetProperty(mixerUnit.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &inBuses, sizeof(UInt32));
		AudioUnitSetProperty(mixerUnit.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Output, 0, &outBuses, sizeof(UInt32));

		/*Set the mixer's input format to have 2 channels*/
		UInt32 inputChannels = 2;
		AudioStreamBasicDescription mixerFormatIn;
		UInt32 size;
		AudioUnitGetProperty(mixerUnit.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &mixerFormatIn, &size);
		mixerFormatIn.mChannelsPerFrame = inputChannels;
		AudioUnitSetProperty(mixerUnit.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &mixerFormatIn, size);

		/*Set the mixer's output format to have 2 channels*/
		UInt32 outputChannels = 2;
		AudioStreamBasicDescription mixerFormatOut;
		AudioUnitGetProperty(mixerUnit.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mixerFormatOut, &size);
		mixerFormatOut.mChannelsPerFrame = outputChannels;

		AudioUnitSetProperty(mixerUnit.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &mixerFormatOut, size);

		completionHandler(mixerUnit);
	}];
}

+ (void)postPlaySetup: (AVAudioUnit *)unit {
	AVAudioUnit* mixerUnit = unit;

	/*Set all matrix volumes to 1*/

	/*Set the master volume*/
	AudioUnitSetParameter(mixerUnit.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Global, 0xFFFFFFFF, 1.0, 0);

	UInt32 inputChannels = 2;
	UInt32 outputChannels = 2;

	for(UInt32 i = 0; i < inputChannels; i++) {

		/*Set input volumes*/
		AudioUnitSetParameter(mixerUnit.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Input, i, 1.0, 0);

		for(UInt32 j = 0; j < outputChannels; j++) {
			/*Set output volumes (only one outer iteration necessary)*/
			if(i == 0) {
				AudioUnitSetParameter(mixerUnit.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Output, j, 1.0, 0);
			}

			/*Set cross point volumes - 1.0 for corresponding
			 inputs/outputs, otherwise 0.0*/
			UInt32 crossPoint = (i << 16) | (j & 0x0000FFFF);
			AudioUnitSetParameter(mixerUnit.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Global, crossPoint, (i == j) ? 1.0 : 0.0, 0);
		}

	}
}


@end
