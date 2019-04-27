//
//  VisualizerWindowController+MIDI.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import MIKMIDI

extension VisualizerViewController {
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
                visualizerView.colorVariance = value
            case 1:
                visualizerView.brightness = value
            case 2:
                visualizerView.psychedelic = value
            case 3:
                visualizerView.details = value
            case 4:
                visualizerView.frantic = value
            default:
                break
            }
        }
    }
}
