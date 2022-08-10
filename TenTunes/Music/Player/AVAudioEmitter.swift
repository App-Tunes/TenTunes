//
//  SinglePlayer.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 12.07.22.
//  Copyright © 2022 ivorius. All rights reserved.
//

import AVFoundation
import TunesLogic

@objc class AVAudioEmitter: NSObject {
	let engine: AVAudioEngine
	let node: AVSeekableAudioPlayerNode

	let environmentMixer: AVAudioEnvironmentNode

	let leftSpeaker: AVAudioMixerNode
	let rightSpeaker: AVAudioMixerNode
	
	let leftDownmixer: AVAudioUnit
	let rightDownmixer: AVAudioUnit
			
	init(
		engine: AVAudioEngine,
		node: AVSeekableAudioPlayerNode,
		environmentMixer: AVAudioEnvironmentNode,
		leftSpeaker: AVAudioMixerNode,
		rightSpeaker: AVAudioMixerNode,
		leftDownmixer: AVAudioUnit,
		rightDownmixer: AVAudioUnit
	) {
		self.engine = engine
		
		self.node = node
		self.environmentMixer = environmentMixer
		
		self.leftSpeaker = leftSpeaker
		self.rightSpeaker = rightSpeaker
		self.leftDownmixer = leftDownmixer
		self.rightDownmixer = rightDownmixer
	}
}

