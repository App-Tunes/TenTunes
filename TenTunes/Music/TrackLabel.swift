//
//  Label.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc public class PlaylistRules : NSObject, NSCoding {
    var labels: [TrackLabel]
    
    func filter(in context: NSManagedObjectContext) -> ((Track) -> Bool) {
        let filters = labels.map { $0.filter(in: context) }
        return { track in
            return filters.allMatch { $0(track) }
        }
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(labels, forKey: "labels")
    }

    public required init?(coder aDecoder: NSCoder) {
        labels = (aDecoder.decodeObject(forKey: "labels") as? [TrackLabel?])?.compactMap { $0 } ?? []
    }
    
    init(labels: [TrackLabel] = []) {
        self.labels = labels
    }
    
    public override var description: String {
        return "[\((labels.map { $0.representation() }).joined(separator: ", "))]"
    }
    
    public override var hashValue: Int {
        return (labels.map { $0.representation() }).reduce(0, { (hash, string) in
            hash ^ string.hash
        })
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? PlaylistRules else {
            return false
        }
        
        return labels == object.labels
    }
}

@objc class TrackLabel : NSObject, NSCoding {
    var not = false
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(not, forKey: "not")
    }
    
    override init() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        not = aDecoder.decodeBool(forKey: "not")
    }
    
    func filter(in context: NSManagedObjectContext) -> (Track) -> Bool {
        let positive = positiveFilter(in: context)
        return not ? { !positive($0) } : positive
    }
    
    func positiveFilter(in context: NSManagedObjectContext) -> (Track) -> Bool {
        return { _ in return false }
    }
    
    func representation(in context: NSManagedObjectContext? = nil) -> String {
        // TODO Use red background instead when possible
        return (not ? "🚫 " : "") + positiveRepresentation(in: context)
    }

    func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String { return "" }
    
    var data : NSData { return NSKeyedArchiver.archivedData(withRootObject: self) as NSData }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TrackLabel else {
            return false
        }
        return data == object.data
    }
}

class LabelSearch : TrackLabel {
    var string: String
    
    init(string: String) {
        self.string = string
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let string = aDecoder.decodeObject(forKey: "string") as? String else {
            return nil
        }
        self.string = string
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(string, forKey: "string")
        super.encode(with: aCoder)
    }
    
    override func positiveFilter(in context: NSManagedObjectContext?) -> (Track) -> Bool {
        return PlayHistory.filter(findText: string)!
    }
    
    override func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String {
        return "Search: " + string
    }
}

class LabelPlaylist : TrackLabel {
    var playlistID: NSManagedObjectID?
    var isTag: Bool
    
    init(playlist: Playlist?, isTag: Bool) {
        self.playlistID = playlist?.objectID
        self.isTag = isTag
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        playlistID = (aDecoder.decodeObject(forKey: "playlistID") as? URL) ?=> Library.shared.persistentStoreCoordinator.managedObjectID
        isTag = aDecoder.decodeBool(forKey: "isTag")
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(isTag, forKey: "isTag")
        aCoder.encode(playlistID?.uriRepresentation(), forKey: "playlistID")
        super.encode(with: aCoder)
    }
    
    func playlist(in context: NSManagedObjectContext) -> Playlist? {
        guard let playlistID = self.playlistID else {
            return nil
        }
        return Library.shared.playlist(byId: playlistID, in: context)
    }
    
    override func positiveFilter(in context: NSManagedObjectContext) -> (Track) -> Bool {
        guard let tracks = playlist(in: context)?.tracksList else {
            return super.filter(in: context)
        }
        
        let trackIDs = tracks.map { $0.objectID }
        
        return { track in
            return trackIDs.contains(track.objectID)
        }
    }
    
    override func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String {
        let playlistName = context != nil ? playlist(in: context!)?.name : playlistID?.description
        return (isTag ? "🏷 " : "📁 ") + (playlistName ?? "Invalid Playlist")
    }
}

class LabelAuthor : TrackLabel {
    var author: String
    
    init(author: String) {
        self.author = author
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let author = aDecoder.decodeObject(forKey: "author") as? String else {
            return nil
        }
        self.author = author
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(author, forKey: "author")
        super.encode(with: aCoder)
    }
    
    override func positiveFilter(in context: NSManagedObjectContext?) -> (Track) -> Bool {
        return { $0.rAuthor.lowercased() == self.author.lowercased() }
    }
    
    override func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String {
        return "👥 " + author
    }
}

class LabelAlbum : TrackLabel {
    var album: Album
    
    init(album: Album) {
        self.album = album
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let title = aDecoder.decodeObject(forKey: "title") as? String, let author = aDecoder.decodeObject(forKey: "author") as? String else {
            return nil
        }
        self.album = Album(title: title, by: author)
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(album.title, forKey: "title")
        aCoder.encode(album.author, forKey: "author")
        super.encode(with: aCoder)
    }
    
    override func positiveFilter(in context: NSManagedObjectContext?) -> (Track) -> Bool {
        return { Album(of: $0) == self.album }
    }
    
    override func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String {
        return "💿 \(album.title) 👥 \(album.author)"
    }
}

class LabelGenre : TrackLabel {
    var genre: String
    
    init(genre: String) {
        self.genre = genre
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let genre = aDecoder.decodeObject(forKey: "genre") as? String else {
            return nil
        }
        self.genre = genre
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(genre, forKey: "genre")
        super.encode(with: aCoder)
    }
    
    override func positiveFilter(in context: NSManagedObjectContext?) -> (Track) -> Bool {
        return { $0.genre?.lowercased() == self.genre.lowercased() }
    }
    
    override func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String {
        return "📗 " + genre
    }
}
