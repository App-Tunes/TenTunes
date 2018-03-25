//
//  ITunesImporter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class ITunesImporter {
    static func importFrom(url: URL, to library: Library) -> Bool {
        guard let nsdict = NSDictionary(contentsOf: url) else {
            return false
        }
        
        // TODO Store persistent IDs for playlists and tracks so we can automatically update them
        // i.e. We have a non-editable 'iTunes' folder that has a right click update and cannot be edit
        // Though it needs to be duplicatable into an editable copy
        
        let mox = Library.shared.viewContext
        
        // TODO Async
        let masterPlaylist = PlaylistFolder()
        masterPlaylist.name = "iTunes Library"
        library.addPlaylist(masterPlaylist)
        
        var existingTracks: [String:Track] = [:]
        // TODO Request
        for track in Library.shared.allTracks.tracksList {
            if let iTunesID = track.iTunesID {
                existingTracks[iTunesID] = track
            }
        }
        
        var iTunesTracks: [Int:Track] = [:]
        var iTunesPlaylists: [String:Playlist] = [:]
        
        for (_, trackData) in nsdict.object(forKey: "Tracks") as! NSDictionary {
            let trackData = trackData as! NSDictionary
            let persistentID =  trackData["Persistent ID"] as! String
            
            let track = existingTracks[persistentID] ?? Track()
            
            iTunesTracks[trackData["Track ID"] as! Int] = track
            
            track.iTunesID = persistentID
            track.title = track.title ?? trackData["Name"] as? String
            track.author = track.author ?? trackData["Artist"] as? String
            track.album = track.album ?? trackData["Album"] as? String
            track.path = track.path ?? trackData["Location"] as? String
            
            if existingTracks[persistentID] == nil {
                mox.insert(track)
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
            let playlist = isFolder ? PlaylistFolder() : PlaylistManual()
            
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
            
            mox.insert(playlist) // Since we don't use existing ones, we don't run into problems inserting every time
            iTunesPlaylists[persistentID] = playlist
            
            if let playlist = playlist as? PlaylistManual, let tracks = tracks {
                playlist.addTracks(tracks)
            }
            
            if let parent = playlistData.object(forKey: "Parent Persistent ID") as? String {
                library.addPlaylist(playlist, to: iTunesPlaylists[parent] as! PlaylistFolder)
            }
            else {
                library.addPlaylist(playlist, to: masterPlaylist)
            }
        }
        
        try! mox.save()
        
        return true
    }
}
