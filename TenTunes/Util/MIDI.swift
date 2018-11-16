//
//  MIDI.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import MIKMIDI

class MIDI: NSObject {
    typealias Number = Float
    
    static var currentConnectionToken: Any?
    @objc static dynamic var numbers: [Number] = []
    
    static func stop() {
        if let token = currentConnectionToken {
            MIKMIDIDeviceManager.shared.disconnectConnection(forToken: token)
        }
    }
    
    static func start(listenOn source: MIKMIDISourceEndpoint, values: Int) {
        stop()
        
        if numbers.count != values {
            numbers = Array(repeating: 0, count: values)
        }
        
        do {
            currentConnectionToken = try MIKMIDIDeviceManager.shared.connectInput(source) { (source, commands) in
                var numbers = MIDI.numbers

                for case let command as MIKMIDIControlChangeCommand in commands {
                    numbers[safe: Int(command.controllerNumber)] = Float(command.controllerValue) / 127
                }
                
                MIDI.numbers = numbers
            }
        }
        catch {
            NSAlert(error: error).runModal()
        }
    }
}
