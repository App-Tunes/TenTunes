//
//  OutputDeviceSelector.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.10.20.
//  Copyright © 2020 ivorius. All rights reserved.
//

import SwiftUI
import AudioKit

@available(OSX 10.15, *)
class AudioDeviceProxy: NSObject, ObservableObject {
    enum Option: Equatable {
        case systemDefault
        
        case device(_ device: AKDevice)
        
        var id: UInt32 {
            switch self {
            case .systemDefault:
                return 0
            case .device(let device):
                return device.deviceID
            }
        }
        
        var name: String {
            switch self {
            case .systemDefault:
                return "System Default"
            case .device(let device):
                if device.deviceID == 46 {
                    return "Computer"
                }
                
                return device.name
            }
        }
        
        var icon: String {
            switch self {
            case .systemDefault:
                return "􀀀"
            case .device(let device):
                if device.deviceID == 46 {
                    return "􀙗"
                }
                
                return "􀝎"
            }
        }
    }
    
    override init() {
        super.init()
        
        AKManager.addObserver(self, forKeyPath: #keyPath(AKManager.outputDevices), options: [.new], context: nil)
        AKManager.addObserver(self, forKeyPath: #keyPath(AKManager.outputDevice), options: [.new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("Change!")
        objectWillChange.send()
    }
    
    func link(_ option: Option) throws {
        var linkDevice: AKDevice? = nil
        
        switch option {
        case .systemDefault:
            linkDevice = AKManager.devices?
                .filter { $0.deviceID == CoreAudioTT.defaultOutputDevice }
                .first
        case .device(let device):
            linkDevice = device
        }
        
        if let device = linkDevice {
            try AKManager.setOutputDevice(device)
            if AKManager.engine.isRunning {
                try AKManager.stop()
                try AKManager.start()
            }

            // TODO Observers don't work :(
            objectWillChange.send()
        }
    }
    
    var options: [Option] {
        return [.systemDefault] + (AKManager.outputDevices ?? [])
            .map { .device($0) }
            .sorted { $0.id < $1.id }
    }
    
    var current: Option? {
        guard let unit = AKManager.engine.outputNode.audioUnit, let currentID = CoreAudioTT.device(ofUnit: unit) else {
            return nil
        }
                        
        return options.filter { $0.id == currentID }.first
    }
}

@available(OSX 10.15, *)
struct OutputDeviceSelector: View {
    
    @ObservedObject var proxy = AudioDeviceProxy()
    @State private var hoverOption: AudioDeviceProxy.Option?
    
    func optionView(_ option: AudioDeviceProxy.Option) -> some View {
        HStack {
            Text(option.icon)
                .frame(width: 25, alignment: .leading)
            Text(option.name)
                .frame(width: 300, alignment: .leading)
            
            Text("􀆅").foregroundColor(Color.white.opacity(
                proxy.current == option ? 1 :
                hoverOption == option ? 0.2 :
                0
            ))
                .frame(width: 25, alignment: .leading)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(proxy.options, id: \.id) { option in
                optionView(option)
                    .padding()
                    .background(hoverOption == option ? Color.gray.opacity(0.2) : nil)
                    .onHover { over in
                        self.hoverOption = over ? option : nil
                    }
                    .onTapGesture {
                        do {
                            try self.proxy.link(option)
                        }
                        catch let error {
                            NSAlert.informational(title: "Unable to switch output device", text: error.localizedDescription)
                        }
                    }
            }
        }
    }
}

@available(OSX 10.15, *)
struct OutputDeviceSelector_Previews: PreviewProvider {
    static var previews: some View {
        OutputDeviceSelector()
    }
}
