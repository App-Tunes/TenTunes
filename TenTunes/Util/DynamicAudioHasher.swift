//
//  DynamicFileHash.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import AVFAudio

class DynamicAudioHasher: NSObject {
    let hashFunction: (URL, Int, Int) -> (Data, Bool)?
    
    var entries: [Data: Entry] = [:]
    var cache: [URL: PartialAudioHash] = [:]
    
    init(at url: URL) {
        self.hashFunction = DynamicAudioHasher.md5Audio
        
        super.init()
        
        collect(at: url)
    }
    
    static func md5Audio(url: URL, start: Int, end: Int) -> (Data, Bool)? {
        guard let file = try? AVAudioFile(forReading: url) else {
            print("Failed to create audio file for \(url)")
            return nil
        }
        
        let readLength = AVAudioFrameCount(min(AVAudioFramePosition(end), file.length))
        let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                      frameCapacity: readLength)
        
        do {
            try file.read(into: buffer!, frameCount: readLength)
        } catch let error as NSError {
            print("error cannot readIntBuffer, Error: \(error)")
        }
        
        let hash = buffer!.withUnsafePointer {
            Hash.md5(of: $0.advanced(by: start), length: $1 - start)
        }
        
        return (hash, AVAudioFramePosition(end) >= file.length)
    }

    func collect(at topURL: URL) {
        for url in FileManager.default.regularFiles(inDirectory: topURL) {
            collect(fileAt: url)
        }
    }
    
    @discardableResult
    func collect(fileAt url: URL) -> PartialAudioHash? {
        guard let partialHash = hash(fileAt: url) else {
            // File unhashable
            return nil
        }
        
        while true {
            let curHash = partialHash.longest
            
            guard let existing = entries[curHash] else {
                // We have found an empty spot! Yay!
                entries[curHash] = .hashPoint(hash: partialHash)
                cache[partialHash.url] = partialHash
                
                return partialHash
            }
            
            switch existing {
            case .hashMore:
                if computeNextHash(for: partialHash) == nil {
                    print("Discarding 'incomplete' file \( url )!")
                    return nil
                }
            case .hashPoint(let other):
                if other.isComplete && partialHash.isComplete {
                    // Same file, doesn't matter which we keep
                    cache[partialHash.url] = partialHash
                    
                    return partialHash
                }

                entries[other.hashes.last!] = .hashMore
                computeNextHash(for: other)
                entries[other.hashes.last!] = .hashPoint(hash: other)
            }
        }
    }
    
    func find(url: URL) -> URL? {
        guard let partialHash = hash(fileAt: url) else {
            // File unhashable
            return nil
        }

        while true {
            let curHash = partialHash.longest
            
            guard let existing = entries[curHash] else {
                return nil
            }
            
            switch existing {
            case .hashMore:
                break
            case .hashPoint(let other):
                return other.url
            }
            
            if computeNextHash(for: partialHash) == nil {
                print("Ignoring 'incomplete' file \( url )!")
                return nil
            }
        }
    }
    
    func hash(fileAt url: URL) -> PartialAudioHash? {
        if let existing = cache[url] {
            return existing
        }

        let hash = PartialAudioHash(url: url)
        guard computeNextHash(for: hash) != nil else {
            return nil
        }
        
        cache[url] = hash
        return hash
    }
    
    @discardableResult
    func computeNextHash(for partialHash: PartialAudioHash) -> Data? {
        guard !partialHash.isComplete else {
            return nil
        }
        
        let prevHashEnd = PartialAudioHash.hashEnd(iteration: partialHash.hashes.count - 1)
        let hashEnd = PartialAudioHash.hashEnd(iteration: partialHash.hashes.count)

        guard let (hash, isComplete) = hashFunction(partialHash.url, prevHashEnd, hashEnd) else {
            return nil
        }
        
        partialHash.hashes.append(hash)
        partialHash.isComplete = isComplete
        
        return hash
    }
    
    enum Entry {
        case hashMore
        case hashPoint(hash: PartialAudioHash)
    }
    
    class PartialAudioHash {
        static let skipHashes = 12

        var url: URL
        var hashes: [Data] = []
        var isComplete = false
        
        init(url: URL) {
            self.url = url
        }
        
        static func hashEnd(iteration: Int) -> Int {
            return iteration < 0
                ? 0
				: Int(pow(2, Double(PartialAudioHash.skipHashes + iteration)).rounded())
        }
        
        var longest: Data {
            return hashes.last!
        }
    }
}
