//
//  Library+iTunes.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 07.05.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

func writeiTunesLibraryXML(tracks: [Track], playlists: [Playlist]) {
    var dict: [String: Any] = [:]
    
    dict["Major Version"] = 1
    dict["Minor Version"] = 1
    
    dict["Application Version"] = "12.7.3.46"
    dict["Date"] = NSDate()
    dict["Features"] = 5 // TODO? Wat is dis
    dict["Show Content Ratings"] = true
    dict["Library Persistent ID"] = "ABX" // TODO Hex String
    
    let to16Hex: (UUID) -> String = { $0.uuidString.replacingOccurrences(of: "-", with: "")[0...15] }
    
    let tracksDicts: [String: Any] = Dictionary(uniqueKeysWithValues: tracks.enumerated().map { (idx, track) in
        var trackDict: [String: Any] = [:]
        
        trackDict["Track ID"] = idx
        trackDict["Name"] = track.title
        trackDict["Artist"] = track.author
        trackDict["Album"] = track.album
        trackDict["Location"] = track.path
        trackDict["Genre"] = track.genre
        trackDict["BPM"] = track.bpm ?=> Int.init
        trackDict["Persistent ID"] = track.iTunesID ?? to16Hex(track.id) // TODO
        
        return (String(idx), trackDict)
    })
    dict["Tracks"] = tracksDicts
    
    let playlistPersistentID: (Playlist) -> String = { $0.iTunesID ?? to16Hex($0.id)  } // TODO
    
    let trackIDs: [Track: Int] = Dictionary(uniqueKeysWithValues: tracks.enumerated().map { (idx, track) in (track, idx) })
    let playlistsArray: [[String: Any]] = playlists.enumerated().map { tuple in
        let (idx, playlist) = tuple // TODO Destructure in param (later Swift)
        var playlistDict: [String: Any] = [:]
        
        playlistDict["Playlist ID"] = idx
        playlistDict["Name"] = playlist.name
        playlistDict["Playlist Persistent ID"] = playlistPersistentID(playlist)
        if playlist.parent != nil {
            playlistDict["Parent Persistent ID"] = playlistPersistentID(playlist.parent!)
        }
        
        var tracks = playlist.tracksList
        if playlist == masterPlaylist {
            tracks = allTracks.tracksList
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
    
    dict["Music Folder"] = directory.appendingPathComponent("Media").absoluteString
    
    (dict as NSDictionary).write(toFile: exportURL(title: "iTunes Library.xml", directory: false).path, atomically: true)
}
