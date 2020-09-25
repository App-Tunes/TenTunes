//
//  VisualizerViewController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 27.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

import MIKMIDI
import AudioKit

class VisualizerViewController: NSViewController {
    var audioSource: Visualizer.AudioCapture = .direct {
        didSet { updateFFT() }
    }
    
    var videoMode: VideoMode = .honey {
        didSet { updateVideoMode() }
    }
    
    @objc dynamic var connection: AudioConnection?
    @objc dynamic var volume: Double = 1 {
        didSet {
            connection?.fft.volume = volume
        }
    }
    
    var silence: AKNode?
    var tracker: AKFrequencyTracker?
    
    var syphon: LiveSyphonServer?
    
    var hidesWindowButtons = true
        
    @IBOutlet var _settingsButton: NSButton!
    @IBOutlet var _settingsSheet: NSPanel!

    @IBOutlet var _modeSelector: NSPopUpButton!
    @IBOutlet var _audioSourceSelector: NSPopUpButton!
    @IBOutlet var _renderingMethodSelector: NSPopUpButton!
    @IBOutlet var _midiSourceSelector: NSPopUpButton!
    
    @IBOutlet var _windowWidth: EnterReturningTextField!
    @IBOutlet var _windowHeight: EnterReturningTextField!
    
    @IBOutlet var visualizerView: VisualizerView! {
        didSet {
            visualizerView.translatesAutoresizingMaskIntoConstraints = false
            
            if let old = oldValue {
                view.replaceSubview(old, with: visualizerView)
            }
            
            view.addConstraints(NSLayoutConstraint.copyLayout(from: view, for: visualizerView))
            
            // Re-Setup Output
            selectedRenderingMethod(_renderingMethodSelector!)
        }
    }
    
    class func create() -> VisualizerViewController {
        let controller = VisualizerViewController(nibName: .init("VisualizerViewController"), bundle: .main)
        return controller
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setControlsHidden(true)
        
        PopupEnum.represent(in: _modeSelector, with: [
            VideoMode.honey, VideoMode.darkMatter
        ], title: { v in v.rawValue })
        
        AKManager.addObserver(self, forKeyPath: #keyPath(AKManager.inputDevices), options: [.new, .initial], context: nil)
        MIKMIDIDeviceManager.shared.addObserver(self, forKeyPath: #keyPath(MIKMIDIDeviceManager.virtualSources), options: [.new, .initial], context: nil)
        
//        let urlRef = Bundle.main.url(forResource: "example_dog", withExtension: "jpg")! as CFURL
//        let myImageSourceRef = CGImageSourceCreateWithURL(urlRef, nil)
//        let myImageRef = CGImageSourceCreateImageAtIndex(myImageSourceRef!, 0, nil)
//        _visualizerView.maskImage = myImageRef
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AKManager.inputDevices) {
            updateAudioSources()
        }
        else if keyPath == #keyPath(ResonanceProvider.resonance) {
            visualizerView.update(withFFT: (object as! ResonanceProvider).resonance.map(Float.init))
        }
        else if keyPath == #keyPath(MIKMIDIDeviceManager.virtualSources) {
            updateMIDISources()
        }
        else if keyPath == #keyPath(MIDI.numbers) {
            updateFromMIDI()
        }
    }
    
    @IBAction func showSettings(_ sender: Any) {
        view.window?.beginSheet(_settingsSheet)
    }
    
    @IBAction func updateWindowSize(_ sender: Any) {
        guard let width = Int(_windowWidth.stringValue), let height = Int(_windowHeight.stringValue) else {
            return
        }
        view.window?.setContentSize(NSSize(width: width, height: height))
    }
    
    override func viewWillTransition(to newSize: NSSize) {
        _windowWidth.stringValue = String(Int(newSize.width))
        _windowHeight.stringValue = String(Int(newSize.height))
    }
    
    override func viewDidAppear() {
        updateFFT()
    }
    
    override func viewDidDisappear() {
        updateFFT()
    }
}

extension VisualizerViewController : VisualizerViewDelegate {
    func setControlsHidden(_ hidden: Bool) {
        _settingsButton.isHidden = hidden
        
        if let window = view.window {
            let alpha: CGFloat = hidden ? 0.01 : 0.35
            window.standardWindowButton(.closeButton)!.alphaValue = alpha
            window.standardWindowButton(.zoomButton)!.alphaValue = alpha
            window.standardWindowButton(.miniaturizeButton)!.alphaValue = alpha
        }
    }
    
    func visualizerViewUpdate(_ view: VisualizerView) {
        // Update on fft changes
//        view.update(withFFT: fft?.resonance)
    }
    
    func togglePlay() -> AnyObject {
        return connection?.pause?() as AnyObject
    }
}
