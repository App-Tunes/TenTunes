//
//  MediaFolder.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AudioKit

class MediaLocation {
    var directory: URL
    
    init(directory: URL) {
        self.directory = directory
        
        // TODO Clean up Garbage in the Media directory. ITS OURS
        // Move it to 'media-trash' or something :D
    }
    
    func updateLocations(of tracks: [Track], copy: Bool = false) {
        for track in tracks {
            updateLocation(of: track, copy: copy)
        }
        
        try! tracks.first?.managedObjectContext?.save()
    }
    
    func updateLocation(of track: Track, copy: Bool = false) {
        guard track.usesMediaDirectory else {
            return
        }
        
        guard let src = track.liveURL else {
            return
        }
        
        let dst = realisticLocation(for: track)
        
        guard dst != src else {
            return
        }
        
        try! dst.ensurePathExists()

        if copy {
            try! FileManager.default.copyItem(at: src, to: dst)
        }
        else {
            try! FileManager.default.moveItem(at: src, to: dst)
        }
        
        check(url: src.deletingLastPathComponent())
        track.path = dst.relativePath(from: directory)
    }
    
    func delete(track: Track) {
        guard track.usesMediaDirectory, let url = track.liveURL else {
            return
        }
        
        try! FileManager.default.trashItem(at: url, resultingItemURL: nil)
        check(url: url.deletingLastPathComponent())
    }
    
    func check(url: URL) {
        guard url.absoluteString.starts(with: directory.absoluteString) else {
            return
        }
        
        var component = url
        
        while component != directory {
            guard let children = try? FileManager.default.contentsOfDirectory(at: component, includingPropertiesForKeys: nil, options: []), children.isEmpty else {
                return
            }
            
            try! FileManager.default.removeItem(at: component)
            component = component.deletingLastPathComponent()
        }
    }
    
    func realisticLocation(for track: Track) -> URL {
        var desired = desiredLocation(for: track)
        
        if desired == track.resolvedURL {
            return desired
        }
        
        let ext = desired.pathExtension
        for i in 1...100 {
            if !FileManager.default.fileExists(atPath: desired.path) {
                if i > 1 {
                    print("Avoiding overwriting existing file: " + desired.path)
                }
                
                return desired
            }
            
            desired = desired.deletingPathExtension().deletingPathExtension()
                .appendingPathExtension( String(i)).appendingPathExtension(ext)
        }
        
        fatalError("Given up trying to find a file! Wtf?") // TODO
    }
    
    func desiredLocation(for track: Track) -> URL {
        let pathExtension = track.resolvedURL?.pathExtension ?? ""
        return directory.appendingPathComponent(Artist.describe(track.authors).asFileName)
                        .appendingPathComponent((track.album ?? Album.unknown).asFileName)
                        .appendingPathComponent(track.rTitle)
                        .appendingPathExtension(pathExtension)
    }
    
    func pather(absolute: Bool = false) -> ((Track, URL) -> String?) {
        return { [unowned self] (track, dstURL) in
            guard let url = track.resolvedURL else {
                return nil
            }
            
            if !absolute && url.absoluteString.starts(with: self.directory.absoluteString) {
                return url.relativePath(from: dstURL)!
            }
            
            return url.path
        }
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
    
    static func pather(for libraryURL: URL, absolute: Bool = false) -> ((Track, URL) -> String?) {
        var src: [Data: URL] = [:]
        let dst: LazyMap<URL, Data?> = LazyMap(MediaLocation.md5Audio)
                
        var srcFound = 0
        var srcFailed = 0
        for url in FileManager.default.regularFiles(inDirectory: libraryURL) {
            if let md5 = md5Audio(url: url) {
                if let existing = src[md5] {
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
        
        return { (track, dstURL) in
            guard let url = track.resolvedURL, let hash = dst[url] else {
                return nil
            }
            
            return src[hash]?.relativePath(from: dstURL)
        }
    }
}
