//
//  AVDevice.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 12.07.22.
//  Copyright © 2022 ivorius. All rights reserved.
//

import AVFoundation
import SwiftUI
import TunesUI
import TunesLogic

class AVAudioDevice: AudioDevice {
	static let systemDefault = AVAudioDevice(deviceID: nil)
	
	let deviceID: AudioDeviceID?
	
	init(deviceID: AudioDeviceID?) {
		self.deviceID = deviceID
	}
	
	func prepare(_ file: AVAudioFile) throws -> AVAudioEmitter {
		let engine = AVAudioEngine()
		let node = AVSeekableAudioPlayerNode(file: file)
 
		if let deviceID = deviceID {
			var deviceID = deviceID
			let error = AudioUnitSetProperty(
				engine.outputNode.audioUnit!,
				kAudioOutputUnitProperty_CurrentDevice,
				kAudioUnitScope_Global,
				0,
				&deviceID,
				UInt32(MemoryLayout<String>.size)
			)
			
			if error != .zero {
				throw CoreAudioLogic.OSError(code: error)
			}
		}
		
		let environmentMixer = AVAudioEnvironmentNode()
		environmentMixer.renderingAlgorithm = .HRTFHQ
		environmentMixer.outputType = .headphones
		// Reverb is very basic
//		environmentMixer.reverbParameters.enable = true
//		environmentMixer.reverbParameters.level = 0
//		environmentMixer.reverbParameters.loadFactoryReverbPreset(.mediumRoom)

		engine.attach(environmentMixer)
		engine.connect(environmentMixer, to: engine.outputNode, format: file.processingFormat)


		let leftSpeaker = AVAudioMixerNode()
		let rightSpeaker = AVAudioMixerNode()

		// Should be perfect triangle, i.e. 60º
		leftSpeaker.sourceMode = .pointSource
		leftSpeaker.position = .init(x: -1.5, y: 0, z: -2.6)
//		leftSpeaker.reverbBlend = 0.01
		rightSpeaker.sourceMode = .pointSource
		rightSpeaker.position = .init(x: 1.5, y: 0, z: -2.6)
//		rightSpeaker.reverbBlend = 0.01

		engine.attach(leftSpeaker)
		engine.attach(rightSpeaker)

		engine.connect(leftSpeaker, to: environmentMixer, format: file.processingFormat)
		engine.connect(rightSpeaker, to: environmentMixer, format: file.processingFormat)
		
		
		var leftDownmixer: AVAudioUnit? = nil
		var rightDownmixer: AVAudioUnit? = nil
		
		node.players.forEach {
			engine.attach($0)
		}

		let group = DispatchGroup()
		group.enter()
		group.enter()

		AUMatrixMixerFactory.instantiate(with: engine) {
			leftDownmixer = $0
			group.leave()
		}
		
		AUMatrixMixerFactory.instantiate(with: engine) {
			rightDownmixer = $0
			group.leave()
		}
		
		group.wait()
		
		guard let leftDownmixer = leftDownmixer, let rightDownmixer = rightDownmixer else {
			fatalError()
		}

		engine.attach(leftDownmixer)
		engine.attach(rightDownmixer)

		// TODO We should connect both sub-players, when enough buses are available
		engine.connect(node.primary, to: [
				.init(node: leftDownmixer, bus: 0),
				.init(node: rightDownmixer, bus: 0)
			],
			fromBus: 0,
			format: nil
		)

		engine.connect(leftDownmixer, to: leftSpeaker, format: file.processingFormat)
		engine.connect(rightDownmixer, to: rightSpeaker, format: file.processingFormat)

		engine.prepare()
		try engine.start()

		// TODO For some reason, the file has to be played before postPlaySetup can be called. Maybe because of format interpretation?
		node.primary.scheduleFile(file, at: nil)
		node.primary.play()

		AUMatrixMixerFactory.postPlaySetup(leftDownmixer)
		AudioUnitSetParameter(leftDownmixer.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Output, 1, 0.0, 0);

		AUMatrixMixerFactory.postPlaySetup(rightDownmixer)
		AudioUnitSetParameter(rightDownmixer.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Output, 0, 0.0, 0);

//		node.prepare()
//
//		engine.prepare()
//
//		try engine.start()
				
		return AVAudioEmitter(engine: engine, node: node, environmentMixer: environmentMixer, leftSpeaker: leftSpeaker, rightSpeaker: rightSpeaker, leftDownmixer: leftDownmixer, rightDownmixer: rightDownmixer)
	}

	var isDefault: Bool { deviceID == nil }
	
	var hasOutput: Bool {
		guard let deviceID = deviceID else {
			return true
		}
		
		let address = AudioObjectPropertyAddress(
			selector: kAudioDevicePropertyStreamConfiguration,
			scope: kAudioDevicePropertyScopeOutput
		)
		
		guard let count = try? CoreAudioLogic.getObjectPropertyCount(
			object: deviceID,
			address: address,
			forType: (CFString?).self
		) else {
			return false
		}

		return (try? CoreAudioLogic.withObjectProperty(
			object: deviceID,
			address: address,
			type: AudioBufferList.self,
			count: count,
			map: {
				UnsafeMutableAudioBufferListPointer($0)
					.anySatisfy { $0.mNumberChannels > 0 }
			}
		)) ?? false
	}

	var uid: String? {
		guard let deviceID = deviceID else {
			return "System Default"
		}

		return try? CoreAudioLogic.getObjectProperty(
			object: deviceID,
			address: .init(
				selector: kAudioDevicePropertyDeviceUID,
				scope: kAudioObjectPropertyScopeGlobal,
				element: kAudioObjectPropertyElementMaster
			),
			type: CFString.self
		) as String
	}

	public var name: String? {
		guard let deviceID = deviceID else {
			return "System Default"
		}

		return try? CoreAudioLogic.getObjectProperty(
			object: deviceID,
			address: .init(
				selector: kAudioDevicePropertyDeviceNameCFString,
				scope: kAudioObjectPropertyScopeGlobal
			),
			type: CFString.self
		) as String
	}
	
	var isHidden: Bool {
		guard let id = deviceID ?? CoreAudioLogic.defaultOutputDevice else {
			return true
		}
		
		return (try? CoreAudioLogic.getObjectProperty(
			object: id,
			address: .init(
				selector: kAudioDevicePropertyIsHidden,
				scope: kAudioObjectPropertyScopeOutput
			),
			type: UInt32.self
		) > 0) ?? true
	}
	
	public var transportType: UInt32? {
		guard let id = deviceID ?? CoreAudioLogic.defaultOutputDevice else {
			return nil
		}

		return try? CoreAudioLogic.getObjectProperty(
			object: id,
			address: .init(
				selector: kAudioDevicePropertyTransportType,
				scope: kAudioObjectPropertyScopeGlobal
			),
			type: UInt32.self
		)
	}
		
	public var icon: Image {
		if deviceID == nil {
			return Image(systemName: "circle")
		}
		
		switch transportType {
		case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE:
			return Image(systemName: "wave.3.right.circle")
		case kAudioDeviceTransportTypeBuiltIn:
			return Image(systemName: "laptopcomputer")
		case kAudioDeviceTransportTypeAggregate, kAudioDeviceTransportTypeAutoAggregate, kAudioDeviceTransportTypeVirtual:
			return Image(systemName: "square.stack.3d.down.forward")
		case kAudioDeviceTransportTypeAirPlay:
			return Image(systemName: "airplayaudio")
		default:
			return Image(systemName: "hifispeaker")
		}
	}
	
	public var volume: Double {
		get {
			(deviceID ?? CoreAudioLogic.defaultOutputDevice).flatMap {
				CoreAudioLogic.volume(ofDevice: UInt32($0))
			}.flatMap(Double.init) ?? 0
		}
		set {
			objectWillChange.send()
			(deviceID ?? CoreAudioLogic.defaultOutputDevice).map {
				CoreAudioLogic.setVolume(ofDevice: UInt32($0), Float(newValue))
			}
		}
	}
}

extension AVAudioDevice: Equatable {
	public static func == (lhs: AVAudioDevice, rhs: AVAudioDevice) -> Bool {
		lhs.deviceID == rhs.deviceID
	}
}
