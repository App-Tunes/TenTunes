//
//  PlaylistRules+Tokens.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension SmartPlaylistRules.Token {
    @objc(TenTunes_SmartPlaylistRules_Token_Search)
    class Search : SmartPlaylistRules.Token {
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
        
        override func positiveFilter(in context: NSManagedObjectContext?, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            guard string.count > 0 else {
                return { _ in false }
            }
            
            let terms = (string.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
            return { (track) in
                return terms.allSatisfy { (term) -> Bool in
                    return track.searchable.anySatisfy { (key) -> Bool in
                        return key.range(of: term, options: [.diacriticInsensitive, .caseInsensitive]) != nil
                    }
                }
            }
        }
        
        override func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String {
            return string
        }
    }
    
    @objc(TenTunes_SmartPlaylistRules_Token_InPlaylist)
    class InPlaylist : SmartPlaylistRules.Token {
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
        
        override func positiveFilter(in context: NSManagedObjectContext, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            guard let tracks = playlist(in: context)?.guardedTracksList(rguard: rguard) else {
                return { _ in false }
            }
            
            let trackIDs = Set(tracks.map { $0.objectID })
            
            return { track in
                return trackIDs.contains(track.objectID)
            }
        }
        
        override func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String {
            let playlistName = context != nil ? playlist(in: context!)?.name : playlistID?.description
            return (isTag ? "🏷 " : "📁 ") + (playlistName ?? "Invalid Playlist")
        }
    }
    
    @objc(TenTunes_SmartPlaylistRules_Token_Author)
    class Author : SmartPlaylistRules.Token {
        var author: Artist
        
        init(author: Artist) {
            self.author = author
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            guard let author = aDecoder.decodeObject(forKey: "author") as? String else {
                return nil
            }
            self.author = Artist(name: author)
            super.init(coder: aDecoder)
        }
        
        override func encode(with aCoder: NSCoder) {
            aCoder.encode(author.name, forKey: "author")
            super.encode(with: aCoder)
        }
        
        override func positiveFilter(in context: NSManagedObjectContext?, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            return { $0.authors.contains(self.author) }
        }
        
        override func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String {
            return "👤 " + author.description
        }
    }
    
    @objc(TenTunes_SmartPlaylistRules_Token_InAlbum)
    class InAlbum : SmartPlaylistRules.Token {
        var album: Album
        
        init(album: Album) {
            self.album = album
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            guard let title = aDecoder.decodeObject(forKey: "title") as? String, let author = aDecoder.decodeObject(forKey: "author") as? String else {
                return nil
            }
            self.album = Album(title: title, by: Artist(name: author))
            super.init(coder: aDecoder)
        }
        
        override func encode(with aCoder: NSCoder) {
            aCoder.encode(album.title, forKey: "title")
            aCoder.encode(album.author?.name, forKey: "author")
            super.encode(with: aCoder)
        }
        
        override func positiveFilter(in context: NSManagedObjectContext?, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            return { $0.rAlbum == self.album }
        }
        
        override func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String {
            return "💿 \(album.title) 👤 \(Artist.describe(album.author))"
        }
    }
    
    @objc(TenTunes_SmartPlaylistRules_Token_Genre)
    class Genre : SmartPlaylistRules.Token {
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
        
        override func positiveFilter(in context: NSManagedObjectContext?, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            let lowerGenre = self.genre.lowercased()
            return { $0.genre?.lowercased() == lowerGenre }
        }
        
        override func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String {
            return "📗 " + genre
        }
    }
    
    @objc(TenTunes_SmartPlaylistRules_Token_MinBitrate)
    class MinBitrate : SmartPlaylistRules.Token {
        var bitrate: Int
        
        init(bitrate: Int, above: Bool) {
            self.bitrate = bitrate
            super.init(not: !above)
        }
        
        required init?(coder aDecoder: NSCoder) {
            self.bitrate = aDecoder.decodeInteger(forKey: "kbps")
            super.init(coder: aDecoder)
        }
        
        override func encode(with aCoder: NSCoder) {
            aCoder.encode(bitrate, forKey: "kbps")
            super.encode(with: aCoder)
        }
        
        override func positiveFilter(in context: NSManagedObjectContext?, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            let bitrate = Float(self.bitrate * 1024)
            return { $0.bitrate >= bitrate }
        }
        
        override func representation(in context: NSManagedObjectContext?) -> String {
            return "kbps \(not ? "<" : "≥") \(bitrate)"
        }
    }
    
    @objc(TenTunes_SmartPlaylistRules_Token_InMediaDirectory)
    class InMediaDirectory : SmartPlaylistRules.Token {
        init(_ usesMediaDirectory: Bool) {
            super.init(not: !usesMediaDirectory)
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func encode(with aCoder: NSCoder) {
            super.encode(with: aCoder)
        }
        
        override func positiveFilter(in context: NSManagedObjectContext?, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            return { $0.usesMediaDirectory }
        }
        
        override func representation(in context: NSManagedObjectContext?) -> String {
            return not ? "Linked File" : "In Media Directory"
        }
    }
    
    @objc(TenTunes_SmartPlaylistRules_Token_FileMissing)
    class FileMissing : SmartPlaylistRules.Token {
        init(_ missing: Bool) {
            super.init(not: !missing)
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func encode(with aCoder: NSCoder) {
            super.encode(with: aCoder)
        }
        
        override func positiveFilter(in context: NSManagedObjectContext?, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            return { $0.liveURL == nil }
        }
        
        override func representation(in context: NSManagedObjectContext?) -> String {
            return not ? "File Exists" : "File Missing"
        }
    }
    
    @objc(TenTunes_SmartPlaylistRules_Token_AddedAfter)
    class AddedAfter : SmartPlaylistRules.Token {
        var date: Date
        
        init(date: Date, after: Bool) {
            self.date = date
            super.init(not: !after)
        }
        
        required init?(coder aDecoder: NSCoder) {
            guard let date = aDecoder.decodeObject(forKey: "date") as? Date else {
                return nil
            }
            self.date = date
            super.init(coder: aDecoder)
        }
        
        override func encode(with aCoder: NSCoder) {
            aCoder.encode(date, forKey: "date")
            super.encode(with: aCoder)
        }
        
        override func filter(in context: NSManagedObjectContext, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            return {
//                guard let url = $0.url, let attributes = try? FileManager.default.attributesOfItem(atPath: url.path), let date = attributes[.creationDate] as? NSDate else {
//                    return false
//                }
                let date = $0.creationDate
                return (date.timeIntervalSinceReferenceDate > self.date.timeIntervalSinceReferenceDate) != self.not
            }
        }
        
        override func representation(in context: NSManagedObjectContext?) -> String {
            return (not ? "Before " : "After ") + "\(HumanDates.string(from: date))"
        }
    }
}
