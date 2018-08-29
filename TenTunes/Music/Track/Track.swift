//
//  Track+CoreDataClass.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData
import AVFoundation

@objc(Track)
public class Track: NSManagedObject {
    static let pasteboardType = NSPasteboard.PasteboardType(rawValue: "tentunes.track")
    
    static let unknownAuthor = "Unknown Author"
    static let unknownTitle = "Unknown Title"

    var analysis: Analysis?
    
    @objc dynamic var artwork: NSImage?

    @discardableResult
    func readAnalysis() -> Bool {
        if let analysisData = analysisData {
            if let decoded = NSKeyedUnarchiver.unarchiveObject(with: analysisData as Data) as? Analysis {
                if let analysis = analysis {
                    analysis.set(from: decoded)
                }
                else {
                    analysis = decoded
                }
                return true
            }
        }
        
        return false
    }
    
    func writeAnalysis() {
        analysisData = NSKeyedArchiver.archivedData(withRootObject: analysis!) as NSData
    }
    
    func copyTransient(from: Track) {
        analysis = from.analysis
        artwork = from.artwork
    }
    
    var duration: CMTime? {
        get { return durationR > 0 ? CMTime(value: durationR, timescale: 1000) : nil }
        set(duration) { durationR = duration?.convertScale(1000, method: .roundHalfAwayFromZero).value ?? 0 }
    }
    
    var durationSeconds: Int? {
        guard let duration = duration else { return nil }
        return Int(CMTimeGetSeconds(duration))
    }
    
    var speed: Speed? {
        get { return bpmString ?=> Speed.init }
        set { bpmString = newValue?.write }
    }
    
    var key: Key? {
        get { return keyString ?=> Key.parse }
        set { keyString = newValue?.write }
    }
    
    var rTitle: String {
        return title ?? Track.unknownTitle
    }
    
    var rSource: String {
        return album != nil ? "\(author ?? Artist.unknown) - \(rAlbum)" : (author ?? Artist.unknown)
    }
        
    var authors: [Artist] {
        return ((author ?=> Artist.all) ?? []) + Array(compact: remixAuthor ?=> Artist.init)
    }
    
    var rAlbum: String {
        return album ?? ""
    }
    
    var rArtwork: NSImage {
        return self.artwork ?? NSImage(named: NSImage.Name(rawValue: "music_missing"))!
    }
    
    var rPreview: NSImage {
        return self.artworkPreview ?? NSImage(named: NSImage.Name(rawValue: "music_missing"))!
    }
    
    var rDuration: String {
        guard let duration = duration else { return "" }
        return Int(CMTimeGetSeconds(duration)).timeString
    }
    
    var url: URL? {
        get {
            if let url = path != nil ? URL(string: path!) : nil {
                return FileManager.default.fileExists(atPath: url.path) ? url : nil
            }
            return nil
        }
    }
    
    var searchable: [String] {
        return [rTitle, author ?? Artist.unknown, rAlbum, remixAuthor].compactMap { $0 }
    }
    
    var tags: Set<PlaylistManual> {
        set {
            containingPlaylists = newValue as NSSet
        }
        get {
            // TODO Also consider smart playlists and folders?
            let containing = containingPlaylists as! Set<PlaylistManual>
            return containing.filter { Library.shared.isTag(playlist: $0) }
        }
    }
}

extension Track {
    struct Speed : Comparable {
        static func < (lhs: Track.Speed, rhs: Track.Speed) -> Bool {
            return lhs.beatsPerMinute < rhs.beatsPerMinute
        }
        
        static let zero = Speed(beatsPerMinute: 0)
        
        let beatsPerMinute: Double
        
        var beatsPerSecond: Double { return beatsPerMinute / 60 }
        
        var secondsPerBeat: Double { return 1 / beatsPerSecond }
        
        init(beatsPerMinute: Double) {
            self.beatsPerMinute = beatsPerMinute
        }

        init?(parse string: String) {
            guard let parsed = Double(string) else { return nil }
            self.init(beatsPerMinute: parsed)
        }
    }
}

extension Track.Speed : CustomStringConvertible {
    var write: String {
        return String(beatsPerMinute)
    }
    
    var description: String {
        return String(format: "%.1f", beatsPerMinute)
    }
 
    var attributedDescription: NSAttributedString {
        let title = description
        let color = NSColor(hue: CGFloat(0.5 + (0...0.3).clamp((beatsPerMinute - 70.0) / 300.0)), saturation: CGFloat(0.3), brightness: CGFloat(0.65), alpha: CGFloat(1.0))
        
        return NSAttributedString(string: title, attributes: [.foregroundColor: color])
    }
}
