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
        // TODO lol
        let to16Hex: (String) -> String = { $0.replacingOccurrences(of: "-", with: "")[0...15] }

        let dict = DictionaryExportReorder(dictionary: [:])

        dict[ordered: "Major Version"] = 1
        dict[ordered: "Minor Version"] = 1
        
        dict[ordered: "Application Version"] = "12.7.3.46"
        dict[ordered: "Date"] = NSDate()
        dict[ordered: "Features"] = 5 // TODO? Wat is dis
        dict[ordered: "Show Content Ratings"] = true
        dict[ordered: "Library Persistent ID"] = to16Hex(library.defaultMetadata[NSStoreUUIDKey] as! String)
        
        let tracksDicts: [String: Any] = Dictionary(uniqueKeysWithValues: tracks.enumerated().compactMap { (idx, track) in
            guard track.fireFault() else {
                return nil
            }
            
            var trackDict: [String: Any] = [:]
            
            // Dicts cannot contain nil
            trackDict["Track ID"] = idx
            trackDict["Name"] = track.rTitle
            trackDict["Artist"] = track.author ?? Artist.unknown
            trackDict["Album"] = track.album ?? Album.unknown
            trackDict["Location"] = track.resolvedURL?.path ?? ""
            if let genre = track.genre { trackDict["Genre"] = genre }
            if let bpm = track.bpmString ?=> Int.init { trackDict["BPM"] = bpm } // Needs an int?
            trackDict["Persistent ID"] = track.iTunesID ?? to16Hex(track.id.uuidString) // TODO
            
            return (String(idx), trackDict)
        })
        dict[ordered: "Tracks"] = tracksDicts
        
        let playlistPersistentID: (Playlist) -> String = { $0.iTunesID ?? to16Hex($0.id.uuidString)  } // TODO
        
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
            if let parent = playlist.parent, parent.objectID != library.masterPlaylist.objectID {
                playlistDict["Parent Persistent ID"] = playlistPersistentID(parent)
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
        dict[ordered: "Playlists"] = playlistsArray
        
        dict[ordered: "Music Folder"] = library.directory.appendingPathComponent("Media").absoluteString
        
        let url = self.url(title: "iTunes Library.xml", directory: false)
        try! url.ensurePathExists()
//        (dict as NSDictionary).write(toFile: url.path, atomically: true)
//        let resultFile = try! String(contentsOfFile: url.path)

        do {
            let writtenData = try PropertyListSerialization.data(fromPropertyList: dict.dictionary, format: .xml, options: 0)
            let writtenString = String(data: writtenData, encoding: .utf8)!
            
            // Hack to delete whitespace after </key>, since itunes doesn't do it
            let finalString = Library.Export.keyWhitespaceDeleteRegex.split(string: writtenString).joined(separator: "</key>")
            
            // Replace temporary keys with final keys
            try dict.fix(xml: finalString)
                .write(to: url, atomically: true, encoding: .utf8)
        }
        catch {
            DispatchQueue.main.async {
                print(error)
                NSAlert(error: error).runModal()
            }
        }
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

extension Library.Export {
    class DictionaryExportReorder {
        struct Key {
            let name: String
            let orderName: String
            let regex: NSRegularExpression
            
            init(name: String, orderName: String) {
                self.name = name
                self.orderName = orderName
                regex = try! NSRegularExpression(pattern: "<key>\(orderName)</key>", options: [])
            }
        }
        
        var dictionary: Dictionary<String, Any>
        var keys = [Key]()
        
        init(dictionary: Dictionary<String, Any>) {
            self.dictionary = dictionary
        }
        
        func register(_ key: String) -> Key {
            let key = Key(name: key, orderName: "XMLExport__\(keys.count)")
            keys.append(key)
            return key
        }
        
        subscript (_ key: Key) -> Any? {
            get { return dictionary[key.orderName] }
            set { dictionary[key.orderName] = newValue }
        }
        
        subscript (ordered key: String) -> Any? {
            get { return dictionary[key] }
            set { dictionary[register(key).orderName] = newValue }
        }
        
        subscript (_ key: String) -> Any? {
            get { return dictionary[key] }
            set { dictionary[key] = newValue }
        }
        
        func fix(xml: String) -> String {
            let fixed = NSMutableString(string: xml)
            for key in keys {
                key.regex.replaceMatches(in: fixed, options: [], range: NSMakeRange(0, fixed.length), withTemplate: "<key>\(key.name)</key>")
            }
            return fixed as String
        }
    }
}
