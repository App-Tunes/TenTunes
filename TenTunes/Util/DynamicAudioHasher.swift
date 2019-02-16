//
//  DynamicFileHash.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

import AudioKit

class DynamicAudioHasher: NSObject {
    let hashFunction: (URL) -> Data?
    
    var src: [Data: URL] = [:]
    let dst: LazyMap<URL, Data?>
    
    init(at url: URL) {
        self.hashFunction = DynamicAudioHasher.md5Audio
        self.dst = LazyMap(hashFunction)
        
        super.init()
        
        collect(at: url)
    }
    
    static func md5Audio(url: URL) -> Data? {
        guard let file = try? AKAudioFile(forReading: url) else {
            print("Failed to create audio file for \(url)")
            return nil
        }
        
        let readLength = AVAudioFrameCount(min(ExportPlaylistsController.maxReadLength, file.length))
        let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                      frameCapacity: readLength)
        
        do {
            try file.read(into: buffer!, frameCount: readLength)
        } catch let error as NSError {
            print("error cannot readIntBuffer, Error: \(error)")
        }
        
        return buffer!.withUnsafePointer(block: Hash.md5)
    }

    func collect(at topURL: URL) {
        var srcFound = 0
        var srcFailed = 0
        for url in FileManager.default.regularFiles(inDirectory: topURL) {
            if let md5 = hash(fileAt: url) {
                if let existing = src[md5], existing != url {
                    print("Hash collision between urls \(url) and \(existing)")
                }
                
                src[md5] = url
                srcFound += 1
                
                if srcFound % 100 == 0 {
                    print("Found \(srcFound)")
                }
            }
            else {
                srcFailed += 1
            }
        }
        
        if srcFailed > 0 {
            print("Failed sources: \(srcFailed)")
        }
    }
    
    func hash(fileAt url: URL) -> Data? {
        return dst[url]
    }
    
    func url(for data: Data) -> URL? {
        return src[data]
    }
}
