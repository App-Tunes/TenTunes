//
//  Label.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc public class PlaylistRules : NSObject, NSCoding {
    var labels: [Label]

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(labels, forKey: "labels")
    }
    
    var filter : ((Track) -> Bool) {
        let filters = labels.map { $0.filter() }
        return { track in
            return filters.allMatch { $0(track) }
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        labels = aDecoder.decodeObject(forKey: "labels") as? [Label] ?? []
    }
    
    init(labels: [Label] = []) {
        self.labels = labels
    }
    
    public override var hashValue: Int {
        return (labels.map { $0.representation }).reduce(0, { (hash, string) in
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

@objc class Label : NSObject, NSCoding {
    func encode(with aCoder: NSCoder) {
        
    }
    
    override init() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
    }
    
    func filter() -> (Track) -> Bool {
        return { _ in return false }
    }
    
    var representation: String { return "" }
    
    var data : NSData { return NSKeyedArchiver.archivedData(withRootObject: self) as NSData }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Label else {
            return false
        }
        return data == object.data
    }
}

class LabelSearch : Label {
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
    
    override func filter() -> (Track) -> Bool {
        return PlayHistory.filter(findText: string)!
    }
    
    override var representation: String {
        return "Search: " + string
    }
}

class PlaylistLabel : Label {
    var playlist: Playlist?
    var isTag: Bool
    
    init(playlist: Playlist?, isTag: Bool) {
        self.playlist = playlist
        self.isTag = isTag
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let playlistID = aDecoder.decodeObject(forKey: "playlistID") else {
            return nil
        }
        self.playlist = Library.shared.restoreFrom(playlistID: playlistID)
        isTag = aDecoder.decodeBool(forKey: "isTag")
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(isTag, forKey: "isTag")
        aCoder.encode(playlist ?=> Library.shared.writePlaylistID, forKey: "playlistID")
        super.encode(with: aCoder)
    }
    
    override func filter() -> (Track) -> Bool {
        guard let tracks = playlist?.tracksList else {
            return super.filter()
        }
        
        return { track in
            return (tracks.map { $0.objectID } ).contains(track.objectID)
        }
    }
    
    override var representation: String {
        return (isTag ? "" : "In: ") + (playlist?.name ?? "Invalid Playlist")
    }
}
