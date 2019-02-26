//
//  CartesianRules.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc public class CartesianRules : NSObject, NSCoding {
    var tokens: [CartesianRules.Token]
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(tokens, forKey: "labels")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        tokens = (aDecoder.decodeObject(forKey: "labels") as? [CartesianRules.Token?])?.compactMap { $0 } ?? []
    }
    
    func combinedFilter(in context: NSManagedObjectContext) -> (Track) -> Bool {
        // Every group must have at least one that matches the track
        let matches = combinedMatches(in: context).map {
            $0.map { $0.filter(in: context, rguard: RecursionGuard()) }
        }
        return { track in
            matches.allSatisfy { $0.anySatisfy { $0(track) } }
        }
    }
    
    func combinedMatches(in context: NSManagedObjectContext) -> [[SmartPlaylistRules.Token]] {
        return tokens.map { $0.matches(in: context) }
    }

    func crossProduct(in context: NSManagedObjectContext) -> [Combination] {
        guard tokens.count > 1 else {
            return tokens.first?.matches(in: context).map { source in
                let rules = SmartPlaylistRules(tokens: [source])
                return Combination(name: source.representation(in: context), rules: rules)
                } ?? []
        }
        
        let matches: [[SmartPlaylistRules.Token]] = tokens.map { $0.matches(in: context) }
        
        return matches.innerCrossProduct().map { combinationTokens in
            let name = combinationTokens.map { $0.representation(in: context) }.joined(separator: " | ")
            let rules = SmartPlaylistRules(tokens: combinationTokens)
            return Combination(name: name, rules: rules)
        }
    }
    
    init(tokens: [CartesianRules.Token] = []) {
        self.tokens = tokens
    }
    
    public override var description: String {
        return "[\((tokens.map { $0.representation() }).joined(separator: ", "))]"
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
        
        func matches(in context: NSManagedObjectContext) -> [SmartPlaylistRules.Token] {
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
        
        override func matches(in context: NSManagedObjectContext) -> [SmartPlaylistRules.Token] {
            return playlist(in: context)?.childrenList.map { SmartPlaylistRules.Token.InPlaylist(playlist: $0, isTag: false) } ?? []
        }
        
        override func representation(in context: NSManagedObjectContext? = nil) -> String {
            let playlistName = context != nil ? playlist(in: context!)?.name : playlistID?.description
            return "📁 " + (playlistName ?? "Invalid Playlist")
        }
    }

    @objc(TenTunes_CartesianRules_Token_Artists) class Artists : CartesianRules.Token {
        override func matches(in context: NSManagedObjectContext) -> [SmartPlaylistRules.Token] {
            return Library.shared.allAuthors.map { SmartPlaylistRules.Token.Author(author: $0) }
        }
        
        override func representation(in context: NSManagedObjectContext? = nil) -> String {
            return "👤 Authors"
        }
    }
}

extension CartesianRules {
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
    }
}
