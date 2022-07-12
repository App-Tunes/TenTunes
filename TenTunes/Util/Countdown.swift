//
//  PlayCountDown.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 12.07.22.
//  Copyright © 2022 ivorius. All rights reserved.
//

import Foundation

class Countdown {
	var action: (() -> Void)?
	
	private var timer: Timer?
	private var timeLeft: Double?
	
	init(action: (() -> Void)? = nil) {
		self.action = action
	}
	
	private func start() {
		
	}
	
	func start(for seconds: TimeInterval) {
		timeLeft = nil
		
		timer?.invalidate()
		timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [unowned self] _ in
			self.action?()
		}
	}
	
	func pause() {
		timeLeft = (timer?.fireDate).map { $0.timeIntervalSinceNow } ?? nil
		if (timeLeft ?? 0) <= 0 { timeLeft = nil }
		
		timer?.invalidate()
		timer = nil
	}
	
	func resume() {
		timeLeft.map(start)
	}
	
	func stop() {
		timeLeft = nil
		timer?.invalidate()
		timer = nil
	}
}
