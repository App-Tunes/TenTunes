//
//  SinglePlayer.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 12.07.22.
//  Copyright © 2022 ivorius. All rights reserved.
//

import AVFoundation
import TunesLogic

@objc class SinglePlayer: NSObject {
	let engine = AVAudioEngine()
	let node: AVSeekableAudioPlayerNode
	
	init(node: AVSeekableAudioPlayerNode) {
		self.node = node
	}
	
	func prepare(_ file: AVAudioFile) throws {
		node.players.forEach {
			engine.attach($0)
			engine.connect($0, to: engine.mainMixerNode, format: file.processingFormat)
		}
		node.prepare()
		
		engine.prepare()

		try engine.start()
	}
}
