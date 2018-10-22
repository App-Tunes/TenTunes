//
//  Track+Live.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 01.10.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Track {
    var tagLibFile: TagLibFile? {
        return liveURL ?=> TagLibFile.init
    }
    
    @discardableResult
    func writeToFile(block: (TagLibFile) -> Void) -> Bool {
        if let tlFile = tagLibFile {
            block(tlFile)
            try! tlFile.write()
            return true
        }
        return false
    }

    @objc dynamic var artworkData: Data? {
        get {
            return tagLibFile?.image
        }
        set {
            writeToFile { $0.image = newValue }
        }
    }
    
    @objc dynamic var artwork: NSImage? {
        get {
            return artworkData.flatMap { NSImage(data: $0) }
        }
        set {
            artworkData = newValue?.jpgRepresentation
            forcedVisuals.artworkPreview = Album.preview(for: newValue)
        }
    }
    
    @objc dynamic var partOfSet: String? {
        get {
            return tagLibFile?.partOfSet
        }
        set {
            writeToFile { $0.partOfSet = newValue }
        }
    }
    
    @objc dynamic var albumNumberOfCDs: Int {
        get { return (partOfSet?.split(separator: "/")[safe: 1].flatMap { Int($0) }) ?? 0 }
        set {
            if newValue > 0 {
                partOfSet = "\(albumNumberOfCD)/\(newValue)"
            }
            else if albumNumberOfCD > 0 {
                partOfSet = "\(albumNumberOfCD)"
            }
            else {
                partOfSet = nil
            }
        }
    }
    
    @objc dynamic var albumNumberOfCD: Int {
        get { return (partOfSet?.split(separator: "/")[safe: 0].flatMap { Int($0) }) ?? 0 }
        set {
            if albumNumberOfCDs > 0 {
                partOfSet = "\(newValue)/\(albumNumberOfCDs)"
            }
            else if newValue > 0 {
                partOfSet = "\(newValue)"
            }
            else {
                partOfSet = nil
            }
        }
    }
}
