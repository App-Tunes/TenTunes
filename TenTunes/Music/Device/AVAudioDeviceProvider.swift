//
//  AVAudioDeviceProvider.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 12.07.22.
//  Copyright © 2022 ivorius. All rights reserved.
//

import Foundation
import SwiftUI
import TunesUI
import TunesLogic
import AVFoundation

class AVAudioDeviceProvider: AudioDeviceProvider {
	static func findDevices() -> [AVAudioDevice] {
		do {
			let deviceIDS = try CoreAudioLogic.getObjectPropertyList(
				object: AudioObjectID(kAudioObjectSystemObject),
				address: .init(
					selector: kAudioHardwarePropertyDevices,
					scope: kAudioObjectPropertyScopeGlobal,
					element: kAudioObjectPropertyElementMaster
				),
				type: AudioDeviceID.self
			)
			
			return deviceIDS.compactMap {
				let audioDevice = AVAudioDevice(deviceID: $0)
				return audioDevice.hasOutput && !audioDevice.isHidden ? audioDevice : nil
			}
		}
		catch let error {
			print(error.localizedDescription)
			return []
		}
	}

	lazy var options: [AVAudioDevice] = [.systemDefault] + Self.findDevices()
	
	var icon: Image { Image(systemName: "speaker.wave.2.circle") }
	var color: Color { .primary }
}
