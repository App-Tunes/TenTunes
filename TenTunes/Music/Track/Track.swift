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
    
    static let unknownTitle = "Unknown Title"
    
    var analysis: Analysis?
    
    var library : Library {
        // Not entirely correct if more than one library exist
        // But better than just using Library.shared everywhere to centralise acccesses for the future
        return Library.shared
    }
    
    var resolvedURL: URL? {
        guard let path = path, let url = path.starts(with: "file://") ? URL(string: path) : URL(fileURLWithPath: path, relativeTo: library.mediaLocation.directory).absoluteURL else {
            return nil
        }
        
        return url
    }
    
    var liveURL: URL? {
        guard let url = resolvedURL, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        return url
    }
        
    @objc var artworkPreview: NSImage? {
        get { return visuals?.artworkPreview }
        set { forcedVisuals.artworkPreview = newValue }
    }
    
    var analysisData: NSData? {
        get { return visuals?.analysis }
        set { forcedVisuals.analysis = analysisData }
    }

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
        forcedVisuals.analysis = NSKeyedArchiver.archivedData(withRootObject: analysis!) as NSData
    }
    
    var duration: CMTime? {
        get { return durationR > 0 ? CMTime(value: durationR, timescale: 1000) : nil }
        set { durationR = newValue?.convertScale(1000, method: .roundHalfAwayFromZero).value ?? 0 }
    }
    
    var durationSeconds: Int? {
        guard let duration = duration else { return nil }
        return Int(CMTimeGetSeconds(duration))
    }
    
    @objc dynamic var speed: Speed? {
        get { return bpmString ?=> Speed.init }
        set { bpmString = newValue?.write }
    }
    
    @objc dynamic var key: Key? {
        get { return keyString ?=> Key.parse }
        set { keyString = newValue?.write }
    }
    
    @objc var rTitle: String {
        return title ?? Track.unknownTitle
    }
    
    @objc var rSource: String {
        return album != nil ? "\(author ?? Artist.unknown) - \(album!)" : (author ?? Artist.unknown)
    }
        
    var authors: [Artist] {
        return ((author ?=> Artist.all) ?? []) + Array(compact: remixAuthor ?=> Artist.init)
    }
    
    var rAlbum: Album? {
        return album.map { Album(title: $0, by: (self.albumArtist ?=> Artist.init) ?? self.authors.first) }
    }
    
    @objc var rDuration: String {
        guard let duration = duration else { return "" }
        return Int(CMTimeGetSeconds(duration)).timeString
    }
    
    @objc var rCreationDate: String {
        return HumanDates.string(from: creationDate as Date)
    }
    
    var searchable: [String] {
        return [rTitle, author ?? Artist.unknown, album ?? Album.unknown, remixAuthor].compactMap { $0 }
    }
    
    var tags: Set<PlaylistManual> {
        set {
            let containing = containingPlaylists as! Set<PlaylistManual>
            containingPlaylists = (containing.filter { !self.library.isTag(playlist: $0) }.union(newValue)) as NSSet
        }
        get {
            // TODO Also consider smart playlists and folders?
            let containing = containingPlaylists as! Set<PlaylistManual>
            return containing.filter { self.library.isTag(playlist: $0) }
        }
    }
    
    var relatedTracksSet: Set<Track> {
        get { return relatedTracks as! Set<Track> }
        set { relatedTracks = newValue as NSSet }
    }
    
    override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        return [
            #keyPath(Track.rTitle): [#keyPath(Track.title)],
            #keyPath(Track.rSource): [#keyPath(Track.album), #keyPath(Track.author)],
            #keyPath(Track.rDuration): [#keyPath(Track.durationR)],
            #keyPath(Track.speed): [#keyPath(Track.bpmString)],
            #keyPath(Track.key): [#keyPath(Track.keyString)],
            #keyPath(Track.artworkPreview): [#keyPath(Track.visuals.artworkPreview)],
            #keyPath(Track.rCreationDate): [#keyPath(Track.creationDate)],
            ][key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
    }
}

extension Track {
    @objc(TenTunes_TrackSpeed)
    class Speed : NSObject, Comparable {
        static func < (lhs: Track.Speed, rhs: Track.Speed) -> Bool {
            return lhs.beatsPerMinute < rhs.beatsPerMinute
        }
        
        static let zero = Speed(beatsPerMinute: 0)
        
        @objc let beatsPerMinute: Double
        
        @objc var beatsPerSecond: Double { return beatsPerMinute / 60 }
        
        @objc var secondsPerBeat: Double { return 1 / beatsPerSecond }
        
        init(beatsPerMinute: Double) {
            self.beatsPerMinute = beatsPerMinute
        }

        convenience init?(parse string: String) {
            guard let parsed = Double(string) else { return nil }
            self.init(beatsPerMinute: parsed)
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            return (object as? Speed)?.beatsPerMinute == beatsPerMinute
        }
    }
}

//  : CustomStringConvertible
extension Track.Speed {
    var write: String {
        return String(beatsPerMinute)
    }
    
    override var description: String {
        return String(format: "%.1f", beatsPerMinute)
    }
    
    @objc dynamic var attributes: [NSAttributedString.Key : Any]? {
        let color = NSColor(hue: CGFloat(0.5 + (0...0.3).clamp((beatsPerMinute - 70.0) / 300.0)), saturation: CGFloat(0.3), brightness: CGFloat(0.65), alpha: CGFloat(1.0))

        return [.foregroundColor: color]
    }
}

extension Track {
    static func sortByAlbum(left: Track, right: Track) -> Bool {
        let leftCD = left.albumNumberOfCD
        let rightCD = right.albumNumberOfCD
        
        if leftCD != rightCD {
            return leftCD < rightCD
        }
        
        return left.trackNumber < right.trackNumber
    }
}
