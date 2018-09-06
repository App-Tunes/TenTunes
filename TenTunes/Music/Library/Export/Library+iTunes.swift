//
//  Library+iTunes.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension Library.Export {
    static let keyWhitespaceDeleteRegex = try! NSRegularExpression(pattern: "</key>\\s*", options: [])
    
    func iTunesLibraryXML(tracks: [Track], playlists: [Playlist]) {
        var dict: [String: Any] = [:]
        
        dict["Major Version"] = 1
        dict["Minor Version"] = 1
        
        dict["Application Version"] = "12.7.3.46"
        dict["Date"] = NSDate()
        dict["Features"] = 5 // TODO? Wat is dis
        dict["Show Content Ratings"] = true
        dict["Library Persistent ID"] = "ABX" // TODO Hex String
        
        let to16Hex: (UUID) -> String = { $0.uuidString.replacingOccurrences(of: "-", with: "")[0...15] }
        
        let tracksDicts: [String: Any] = Dictionary(uniqueKeysWithValues: tracks.enumerated().compactMap { (idx, track) in
            guard track.fireFault() else {
                return nil
            }
            
            var trackDict: [String: Any] = [:]
            
            trackDict["Track ID"] = idx
            trackDict["Name"] = track.title
            trackDict["Artist"] = track.author
            trackDict["Album"] = track.album
            trackDict["Location"] = track.path
            trackDict["Genre"] = track.genre
            trackDict["BPM"] = track.bpmString ?=> Int.init // Needs an int?
            trackDict["Persistent ID"] = track.iTunesID ?? to16Hex(track.id) // TODO
            
            return (String(idx), trackDict)
        })
        dict["Tracks"] = tracksDicts
        
        let playlistPersistentID: (Playlist) -> String = { $0.iTunesID ?? to16Hex($0.id)  } // TODO
        
        let trackIDs: [Track: Int] = Dictionary(uniqueKeysWithValues: tracks.enumerated().map { (idx, track) in (track, idx) })
        let playlistsArray: [[String: Any]] = playlists.enumerated().compactMap { tuple in
            let (idx, playlist) = tuple // TODO Destructure in param (later Swift)

            guard playlist.fireFault() else {
                return nil
            }
            
            var playlistDict: [String: Any] = [:]
            
            playlistDict["Playlist ID"] = idx
            playlistDict["Name"] = playlist.name
            playlistDict["Playlist Persistent ID"] = playlistPersistentID(playlist)
            if playlist.parent != nil {
                playlistDict["Parent Persistent ID"] = playlistPersistentID(playlist.parent!)
            }
            
            var tracks = playlist.tracksList
            if playlist.objectID == library.masterPlaylist.objectID {
                tracks = library.allTracks.convert(to: context)!.tracksList
                playlistDict["Master"] = true
                playlistDict["All Items"] = true
                playlistDict["Visible"] = false
            }
            
            playlistDict["Playlist Items"] = tracks.map { track in
                return ["Track ID": trackIDs[track]]
            }
            
            return playlistDict
        }
        dict["Playlists"] = playlistsArray
        
        dict["Music Folder"] = library.directory.appendingPathComponent("Media").absoluteString
        
        let url = self.url(title: "iTunes Library.xml", directory: false)
        try! url.ensurePath()
//        (dict as NSDictionary).write(toFile: url.path, atomically: true)
//        let resultFile = try! String(contentsOfFile: url.path)

        let writtenData = try! PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
        let writtenString = String(data: writtenData, encoding: .utf8)!

        // Hack to delete whitespace after </key>, since itunes doesn't do it
        let finalString = Library.Export.keyWhitespaceDeleteRegex.split(string: writtenString).joined(separator: "</key>")

        try! finalString.write(to: url, atomically: true, encoding: .utf8)
    }
}

extension Library.Import {
    func iTunesLibraryXML(url: URL) -> Bool {
        guard let nsdict = NSDictionary(contentsOf: url) else {
            return false
        }
        
        // TODO Store persistent IDs for playlists and tracks so we can automatically update them
        // i.e. We have a non-editable 'iTunes' folder that has a right click update and cannot be edit
        // Though it needs to be duplicatable into an editable copy
        
        // TODO Async
        let masterPlaylist = PlaylistFolder(context: context)
        context.insert(masterPlaylist)
        masterPlaylist.name = "iTunes Library"
        self.library.masterPlaylist.addPlaylist(masterPlaylist)
        
        var existingTracks: [String:Track] = [:]
        // TODO Request
        for track in library.allTracks.tracksList {
            if let iTunesID = track.iTunesID {
                existingTracks[iTunesID] = track
            }
        }
        
        var iTunesTracks: [Int:Track] = [:]
        var iTunesPlaylists: [String:Playlist] = [:]
        
        for (_, trackData) in nsdict.object(forKey: "Tracks") as! NSDictionary {
            let trackData = trackData as! NSDictionary
            let persistentID =  trackData["Persistent ID"] as! String
            
            let track = existingTracks[persistentID] ?? Track(context: context)
            
            iTunesTracks[trackData["Track ID"] as! Int] = track
            
            track.iTunesID = persistentID
            track.title = track.title ?? trackData["Name"] as? String
            track.author = track.author ?? trackData["Artist"] as? String
            track.album = track.album ?? trackData["Album"] as? String
            track.path = track.path ?? trackData["Location"] as? String
            
            if existingTracks[persistentID] == nil {
                context.insert(track)
            }
        }
        
        for playlistData in nsdict.object(forKey: "Playlists") as! NSArray {
            let playlistData = playlistData as! NSDictionary
            let persistentID = playlistData.object(forKey: "Playlist Persistent ID") as! String
            if playlistData.object(forKey: "Master") as? Bool ?? false {
                continue
            }
            if playlistData.object(forKey: "Distinguished Kind") as? Int != nil {
                continue // TODO At least give the option
            }
            
            //            // TODO Seems to be some kind of binary encoding. See Banshee iTunes Smart Playlist parser for impl ref
            //            if let smartInfoData = playlistData.object(forKey: "Smart Info") as? NSData, let smartCriteriaData = playlistData.object(forKey: "Smart Criteria") as? NSData {
            //                let smartInfo = String(data: smartInfoData as Data, encoding: .utf8)
            //                let smartCriteria = NSKeyedUnarchiver.unarchiveObject(with: smartCriteriaData as Data)
            //            }
            
            let isFolder = playlistData.object(forKey: "Folder") as? Bool ?? false
            let playlist = isFolder ? PlaylistFolder(context: context) : PlaylistManual(context: context)
            
            playlist.name = playlistData.object(forKey: "Name") as! String
            playlist.iTunesID = persistentID
            
            var tracks: [Track]? = nil
            if !isFolder {
                let trackDicts: NSArray = (playlistData.object(forKey: "Playlist Items") as? NSArray ?? [])
                tracks = trackDicts.map { trackData in
                    let trackData = trackData as! NSDictionary
                    let id = trackData["Track ID"] as! Int
                    return iTunesTracks[id]!
                }
            }
            
            context.insert(playlist) // Since we don't use existing ones, we don't run into problems inserting every time
            iTunesPlaylists[persistentID] = playlist
            
            if let playlist = playlist as? PlaylistManual, let tracks = tracks {
                playlist.addTracks(tracks)
            }
            
            if let parent = playlistData.object(forKey: "Parent Persistent ID") as? String {
                (iTunesPlaylists[parent] as! PlaylistFolder).addPlaylist(playlist)
            }
            else {
                masterPlaylist.addPlaylist(playlist)
            }
        }
        
        try! context.save()
        
        for track in existingTracks.values {
            Library.shared.initialAdd(track: track, moveAction: .link)
        }
        
        return true
    }
}
