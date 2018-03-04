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
        }
        
        for playlistData in nsdict.object(forKey: "Playlists") as! NSArray {
            let playlistData = playlistData as! NSDictionary
            if playlistData.object(forKey: "Master") as? Bool ?? false {
                continue
            }
            if playlistData.object(forKey: "Distinguished Kind") as? Int != nil {
                continue // TODO At least give the option
            }
            
            let isFolder = playlistData.object(forKey: "Folder") as? Bool ?? false
            let playlist = isFolder ? PlaylistFolder() : PlaylistManual()
            
            playlist.name = playlistData.object(forKey: "Name") as! String
            
            var tracks: [Track]? = nil
            if !isFolder {
                let trackDicts: NSArray = (playlistData.object(forKey: "Playlist Items") as? NSArray ?? [])
                tracks = trackDicts.map { trackData in
                    let trackData = trackData as! NSDictionary
                    let id = trackData["Track ID"] as! Int
                    return iTunesTracks[id]!
                }
            }
            
            iTunesPlaylists[playlistData.object(forKey: "Playlist Persistent ID") as! String] = playlist
            
            if let playlist = playlist as? PlaylistManual, let tracks = tracks {
                library.addTracks(tracks, to: playlist)
            }
            
            if let parent = playlistData.object(forKey: "Parent Persistent ID") as? String {
                library.addPlaylist(playlist, to: iTunesPlaylists[parent] as! PlaylistFolder)
            }
            else {
                library.addPlaylist(playlist, to: masterPlaylist)
            }
        }

        
        return true
    }
}
