//
//  MediaFolder.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class MediaLocation {
    var directory: URL
    
    init(directory: URL) {
        self.directory = directory
        
        // TODO Clean up Garbage in the Media directory. ITS OURS
        // Move it to 'media-trash' or something :D
    }
    
    static var musicDirectory: URL? {
        return FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first
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
            
            // If delete fails, it might have been deleted by another thread somehwere
            try? FileManager.default.removeItem(at: component)
            component = component.deletingLastPathComponent()
        }
    }
    
    func realisticLocation(for track: Track) -> URL {
        let desired = desiredLocation(for: track)
        let current = track.resolvedURL
        
        guard !URL.areEqualLocally(desired, current) else {
            return desired
        }
        
        let ext = desired.pathExtension
        var realistic = desired
        
        for i in 1...10 {
            if !FileManager.default.fileExists(atPath: realistic.path) {
                if i > 1 {
                    print("Avoiding overwriting existing file: \"\(desired)\" \nusing: \"\(realistic)\" \nprevious path: \"\(String(describing: current))\"")
                }
                
                return realistic
            }
            
            realistic = desired.deletingPathExtension()
                .appendingPathExtension(String(i)).appendingPathExtension(ext)
        }
        
        let finalFile = desired.deletingPathExtension()
            .appendingPathExtension(UUID().uuidString).appendingPathExtension(ext)
        print("Given up trying to find a numbered file due to existing tracks: \"\(desired)\", using: \"\(finalFile)\"")
        return finalFile
    }
    
    func desiredLocation(for track: Track) -> URL {
        let mod: (String) -> String = AppDelegate.defaults[.forceSimpleFilePaths] ? { $0.asSimpleFileName } : { $0.asFileName }
        
        let pathExtension = track.resolvedURL?.pathExtension ?? ""
        return directory.appendingPathComponent(mod(Artist.describe(track.authors)))
                        .appendingPathComponent(mod(track.album ?? Album.unknown))
                        .appendingPathComponent(mod(track.rTitle))
                        .appendingPathExtension(pathExtension)
                        .resolvingSymlinksInPath()
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
        
    static func pather(for hasher: DynamicAudioHasher) -> ((Track, URL) -> String?) {
        return { (track, dstURL) in
            guard let url = track.resolvedURL ?=> hasher.find else {
                return nil
            }
            
            return url.relativePath(from: dstURL)
        }
    }
}
