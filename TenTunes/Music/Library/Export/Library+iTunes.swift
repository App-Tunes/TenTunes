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
    static let fuckingRekordboxManRegex = try! NSRegularExpression(pattern: "-\\/\\/Apple\\/\\/DTD PLIST 1\\.0\\/\\/EN", options: [])

    func iTunesLibraryXML(tracks: [Track], playlists: [Playlist]) {
        // TODO lol
        let to16Hex: (String) -> String = { $0.replacingOccurrences(of: "-", with: "")[0...15] }

        let dict = OrderedDictionary()

        dict[ordered: "Major Version"] = 1
        dict[ordered: "Minor Version"] = 1
        
        dict[ordered: "Application Version"] = "12.9.0.164"
        dict[ordered: "Date"] = NSDate()
        dict[ordered: "Features"] = 5 // TODO? Wat is dis
        dict[ordered: "Show Content Ratings"] = true
        dict[ordered: "Library Persistent ID"] = to16Hex(library.defaultMetadata[NSStoreUUIDKey] as! String)
        
        let tracksDicts: [String: Any] = Dictionary(uniqueKeysWithValues: tracks.enumerated().compactMap { (idx, track) in
            guard track.fireFault() else {
                return nil
            }
            
            let trackDict = OrderedDictionary()
            
            // Dicts cannot contain nil
            trackDict[ordered: "Track ID"] = idx
            
            // TODO Theoretically unacceptable to write exports with live attributes, so store?
//            if let attributes = track.liveFileAttributes {
//                trackDict["Size"] = attributes[FileAttributeKey.size] as! UInt64
//                trackDict["Date Modified"] = attributes[FileAttributeKey.modificationDate] as! NSDate
//            }
            trackDict[ordered: "Total Time"] = track.duration.map { Int($0.seconds * 1000) } ?? 0 // If we don't have a duration it's not playable so to say
            if let bpm = track.bpmString ?=> Int.init { trackDict[ordered: "BPM"] = bpm } // Needs an int?

            if track.year > 0 { trackDict[ordered: "Year"] = track.year }
            trackDict[ordered: "Date Added"] = track.creationDate
            trackDict[ordered: "Bit Rate"] = Int(track.bitrate / 1024)

            trackDict[ordered: "Persistent ID"] = track.iTunesID ?? to16Hex(track.id.uuidString) // TODO
            trackDict[ordered: "Track Type"] = "File" // TODO?

            trackDict[ordered: "Name"] = track.rTitle
            trackDict[ordered: "Artist"] = track.author ?? Artist.unknown
            trackDict[ordered: "Album"] = track.album ?? Album.unknown
            if let genre = track.genre { trackDict[ordered: "Genre"] = genre }

            trackDict[ordered: "Location"] = track.resolvedURL?.absoluteString ?? ""

            
            return (String(idx), trackDict.dictionary)
        })
        dict[ordered: "Tracks"] = tracksDicts
        
        let playlistPersistentID: (Playlist) -> String = { $0.iTunesID ?? to16Hex($0.id.uuidString)  } // TODO
        
        let trackIDs: [Track: Int] = Dictionary(uniqueKeysWithValues: tracks.enumerated().map { (idx, track) in (track, idx) })
        let playlistsArray: [[String: Any]] = playlists.enumerated().compactMap { tuple in
            let (idx, playlist) = tuple // TODO Destructure in param (later Swift)

            guard playlist.fireFault() else {
                return nil
            }
            
            let isMaster = playlist.objectID == library.masterPlaylist.objectID
            let playlistDict = OrderedDictionary()
            
            if isMaster { playlistDict[ordered: "Master"] = true }
            playlistDict[ordered: "Playlist ID"] = idx
            if let parent = playlist.parent, parent.objectID != library.masterPlaylist.objectID {
                playlistDict[ordered: "Parent Persistent ID"] = playlistPersistentID(parent)
            }
            playlistDict[ordered: "Playlist Persistent ID"] = playlistPersistentID(playlist)
            
            var tracks = playlist.tracksList
            if isMaster {
                tracks = library.allTracks.convert(to: context)!.tracksList
                
                playlistDict[ordered: "All Items"] = true
                playlistDict[ordered: "Visible"] = false
            }
            
            if playlist is PlaylistFolder { playlistDict[ordered: "Folder"] = true }
            playlistDict[ordered: "Name"] = playlist.name

            playlistDict[ordered: "Playlist Items"] = tracks.map { track in
                return ["Track ID": trackIDs[track]]
            }
            
            return playlistDict.dictionary
        }
        dict[ordered: "Playlists"] = playlistsArray
        
        dict[ordered: "Music Folder"] = library.directory.appendingPathComponent("Media").absoluteString
        
        let url = self.url(title: "iTunes Library.xml", directory: false)
        try! url.ensurePathExists()
//        (dict as NSDictionary).write(toFile: url.path, atomically: true)
//        let resultFile = try! String(contentsOfFile: url.path)

        do {
            let writtenData = try PropertyListSerialization.data(fromPropertyList: dict.dictionary, format: .xml, options: 0)
            var writtenString = String(data: writtenData, encoding: .utf8)!
            
            // Hack to delete whitespace after </key>, since itunes doesn't do it
            writtenString = Library.Export.keyWhitespaceDeleteRegex.split(string: writtenString).joined(separator: "</key>")
            // Rekordbox needs the doctype to be exact....
            writtenString = Library.Export.fuckingRekordboxManRegex.stringByReplacingMatches(in: writtenString, range: NSMakeRange(0, min(200, writtenString.count)), withTemplate: "-//Apple Computer//DTD PLIST 1.0//EN")
            // Replace temporary keys with final keys
            writtenString = OrderedDictionary.cleanUp(xml: writtenString)
            
            try writtenString.write(to: url, atomically: true, encoding: .utf8)
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
    class OrderedDictionary {
        static let insertString = "_TenTunes_DYNAMIC"
        static let xmlFixRegex = try! NSRegularExpression(pattern: "[0-9]{5}\(OrderedDictionary.insertString)", options: [])
        
        typealias Value = Any
        
        static func cleanUp(xml: String) -> String {
            return xmlFixRegex.stringByReplacingMatches(in: xml, range: NSMakeRange(0, xml.count), withTemplate: "")
        }
        
        var dictionary: Dictionary<String, Value> = [:]
        var idx = 0
        
        subscript (ordered key: String) -> Any? {
            get { fatalError("Unimplemented") }
            set {
                dictionary[String(format: "%05d", idx) + OrderedDictionary.insertString + key] = newValue
                idx += 1
            }
        }
        
        subscript(_ key: String) -> Value? {
            get { return dictionary[key] }
            set { dictionary[key] = newValue }
        }
    }
}
