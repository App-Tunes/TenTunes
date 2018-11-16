//
//  VisualizerWindowController+MIDI.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import MIKMIDI

extension VisualizerWindowController {
    func updateMIDISources() {
        _midiSourceSelector.removeAllItems()
        
        _midiSourceSelector.addItem(withTitle: "None")
        _midiSourceSelector.menu!.addItem(NSMenuItem.separator())
        
        for source in MIKMIDIDeviceManager.shared.virtualSources {
            _midiSourceSelector.addItem(withTitle: source.displayName ?? "Unknown Source")
            _midiSourceSelector.lastItem!.representedObject = source
        }
    }
    
    @IBAction func selectedMIDISource(_ sender: Any) {
        MIDI.stop()
        MIDI.removeObserver(self, forKeyPath: #keyPath(MIDI.numbers))
        
        guard let source = _midiSourceSelector.selectedItem?.representedObject as? MIKMIDISourceEndpoint else {
            return
        }
        
        MIDI.start(listenOn: source, values: 5)
        MIDI.addObserver(self, forKeyPath: #keyPath(MIDI.numbers), options: [.new], context: nil)
    }
    
    func updateFromMIDI() {
        for (idx, value) in MIDI.numbers.enumerated() {
            switch idx {
            case 0:
                _visualizerView.colorVariance = value
            case 1:
                _visualizerView.brightness = value
            case 2:
                _visualizerView.psychedelic = value
            case 3:
                _visualizerView.details = value
            case 4:
                _visualizerView.frantic = value
            default:
                break
            }
        }
    }
}
