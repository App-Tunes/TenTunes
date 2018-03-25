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
    
    func updateLocations(of tracks: [Track], copy: Bool = false) {
        for track in tracks {
            updateLocation(of: track, copy: copy)
        }
        
        try! Library.shared.viewContext.save()
    }
    
    func updateLocation(of track: Track, copy: Bool = false) {
        guard track.usesMediaDirectory else {
            return
        }
        
        guard let src = track.url else {
            return
        }
        
        let dst = location(for: track)
        
        guard dst != src else {
            return
        }
        
        try! FileManager.default.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

        if copy {
            try! FileManager.default.copyItem(at: src, to: dst)
        }
        else {
            try! FileManager.default.moveItem(at: src, to: dst)
        }
        
        check(url: src.deletingLastPathComponent())
        track.path = dst.absoluteString
    }
    
    func delete(track: Track) {
        guard track.usesMediaDirectory, let url = track.url else {
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
            guard try! FileManager.default.contentsOfDirectory(at: component, includingPropertiesForKeys: nil, options: []).count == 0 else {
                return
            }
            
            try! FileManager.default.removeItem(at: component)
            component = component.deletingLastPathComponent()
        }
    }
    
    func location(for track: Track) -> URL {
        var desired = desiredLocation(for: track)
        
        if desired == track.url {
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
            
            desired = desired.deletingPathExtension().appendingPathExtension( String(i)).appendingPathExtension(ext)
        }
        
        fatalError("Given up trying to find a file! Wtf?") // TODO
    }
    
    func desiredLocation(for track: Track) -> URL {
        let pathExtension = track.url?.pathExtension ?? ""
        return directory.appendingPathComponent(track.rAuthor.asFileName)
                        .appendingPathComponent(track.rAlbum.asFileName)
                        .appendingPathComponent(track.rTitle)
                        .appendingPathExtension(pathExtension)
    }
}
