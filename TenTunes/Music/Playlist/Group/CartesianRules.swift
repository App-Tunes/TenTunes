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
        let rules: SmartPlaylistRules
        
        init(name: String, rules: SmartPlaylistRules) {
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

    var tokens: [CartesianRules.Token]
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(tokens, forKey: "labels")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        tokens = (aDecoder.decodeObject(forKey: "labels") as? [CartesianRules.Token?])?.compactMap { $0 } ?? []
    }
    
    func combinedFilter(in context: NSManagedObjectContext) -> (Track) -> Bool {
        // Every group of playlists must have at least one that contains the track
        // So we build a set of all tracks from each group 
        let matches = combinedMatches(in: context).map {
            Set($0.flatMap { $0.tracksList })
        }
        return { track in
            matches.allMatch { $0.contains(track) }
        }
    }
    
    func combinedMatches(in context: NSManagedObjectContext) -> [[Playlist]] {
        return tokens.map({ $0.matches(in: context) })
    }

    func crossProduct(in context: NSManagedObjectContext) -> [Combination] {
        guard tokens.count == 2 else {
            return tokens.first?.matches(in: context).map { source in
                let rules = SmartPlaylistRules(tokens: [.InPlaylist(playlist: source, isTag: false)])
                return Combination(name: source.name, rules: rules)
                } ?? []
        }
        
        return tokens.first!.matches(in: context).crossProduct(tokens.last!.matches(in: context)).map { (left, right) in
            let name = "\(left.name) | \(right.name)"
            let rules = SmartPlaylistRules(tokens: [
                .InPlaylist(playlist: left, isTag: false),
                .InPlaylist(playlist: right, isTag: false)
                ])
            return Combination(name: name, rules: rules)
        }
    }
    
    init(tokens: [CartesianRules.Token] = []) {
        self.tokens = tokens
    }
    
    public override var description: String {
        return "[\((tokens.map { $0.representation() }).joined(separator: ", "))]"
    }
    
    public override var hashValue: Int {
        return (tokens.map { $0.representation() }).reduce(0, { (hash, string) in
            hash ^ string.hash
        })
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SmartPlaylistRules else {
            return false
        }
        
        return tokens == object.tokens
    }
    
    @objc(TenTunes_CartesianRules_Token) class Token : NSObject, NSCoding {
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
            guard let object = object as? CartesianRules.Token else {
                return false
            }
            return data == object.data
        }
    }
}

extension CartesianRules.Token {
    @objc(TenTunes_CartesianRules_Token_Folder) class Folder : CartesianRules.Token {
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
