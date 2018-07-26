//
//  PlaylistRules+Labels.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension TrackLabel {
    class Search : TrackLabel {
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
    
    class InPlaylist : TrackLabel {
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
                return { _ in false }
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
    
    class Author : TrackLabel {
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
    
    class InAlbum : TrackLabel {
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
    
    class Genre : TrackLabel {
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
    
    class MinBitrate : TrackLabel {
        var bitrate: Int
        
        init(bitrate: Int, above: Bool) {
            self.bitrate = bitrate
            super.init()
            not = !above
        }
        
        required init?(coder aDecoder: NSCoder) {
            self.bitrate = aDecoder.decodeInteger(forKey: "kbps")
            super.init(coder: aDecoder)
        }
        
        override func encode(with aCoder: NSCoder) {
            aCoder.encode(bitrate, forKey: "kbps")
            super.encode(with: aCoder)
        }
        
        override func positiveFilter(in context: NSManagedObjectContext?) -> (Track) -> Bool {
            return { $0.bitrate >= Float(self.bitrate * 1024) }
        }
        
        override func representation(in context: NSManagedObjectContext?) -> String {
            return "kbps \(not ? "<" : "≥") \(bitrate)"
        }
    }
}
