//
//  PlaylistLabel.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc public class CartesianRules : NSObject, NSCoding {
    struct Combination : Hashable {
        let name: String
        let rules: PlaylistRules
        
        init(name: String, rules: PlaylistRules) {
            self.name = name
            self.rules = rules
        }
        
        init?(from: Playlist) {
            guard let rules = (from as? PlaylistSmart)?.rules else {
                return nil
            }
            
            self.init(name: from.name, rules: rules)
        }
        
        var hashValue: Int {
            return name.hashValue ^ rules.hashValue
        }
        
        static func == (lhs: Combination, rhs: Combination) -> Bool {
            return lhs.name == rhs.name && lhs.rules == rhs.rules
        }
    }

    var labels: [PlaylistLabel]
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(labels, forKey: "labels")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        labels = (aDecoder.decodeObject(forKey: "labels") as? [PlaylistLabel?])?.compactMap { $0 } ?? []
    }

    func crossProduct(in context: NSManagedObjectContext) -> [Combination] {
        guard labels.count == 2 else {
            return labels.first?.matches(in: context).map { source in
                let rules = PlaylistRules(labels: [TrackLabel.InPlaylist(playlist: source, isTag: false)])
                return Combination(name: source.name, rules: rules)
                } ?? []
        }
        
        return labels.first!.matches(in: context).crossProduct(labels.last!.matches(in: context)).map { (left, right) in
            let name = "\(left.name) | \(right.name)"
            let rules = PlaylistRules(labels: [
                TrackLabel.InPlaylist(playlist: left, isTag: false),
                TrackLabel.InPlaylist(playlist: right, isTag: false)
                ])
            return Combination(name: name, rules: rules)
        }
    }
    
    init(labels: [PlaylistLabel] = []) {
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

@objc class PlaylistLabel : NSObject, NSCoding {
    func encode(with aCoder: NSCoder) {
        
    }
    
    override init() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
    }
    
    func matches(in context: NSManagedObjectContext) -> [Playlist] {
        return []
    }
    
    func representation(in context: NSManagedObjectContext? = nil) -> String { return "" }
    
    var data : NSData { return NSKeyedArchiver.archivedData(withRootObject: self) as NSData }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? PlaylistLabel else {
            return false
        }
        return data == object.data
    }
}

extension PlaylistLabel {
    @objc class Folder : PlaylistLabel {
        var playlistID: NSManagedObjectID?
        
        init(playlist: PlaylistFolder?) {
            self.playlistID = playlist?.objectID
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            playlistID = (aDecoder.decodeObject(forKey: "playlistID") as? URL) ?=> Library.shared.persistentStoreCoordinator.managedObjectID
            super.init(coder: aDecoder)
        }
        
        override func encode(with aCoder: NSCoder) {
            aCoder.encode(playlistID?.uriRepresentation(), forKey: "playlistID")
            super.encode(with: aCoder)
        }
        
        func playlist(in context: NSManagedObjectContext) -> PlaylistFolder? {
            guard let playlistID = self.playlistID else {
                return nil
            }
            return Library.shared.playlist(byId: playlistID, in: context) as? PlaylistFolder
        }
        
        override func matches(in context: NSManagedObjectContext) -> [Playlist] {
            return playlist(in: context)?.childrenList ?? []
        }
        
        override func representation(in context: NSManagedObjectContext? = nil) -> String {
            let playlistName = context != nil ? playlist(in: context!)?.name : playlistID?.description
            return "📁 " + (playlistName ?? "Invalid Playlist")
        }
    }
}
