//
//  ITunesImporter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class ITunesImporter {
    static func parse(path: String) -> ([Int: Track], Playlist)? {
        guard let nsdict = NSDictionary(contentsOfFile: path) else {
            return nil
        }
        
        var database: [Int: Track] = [:]
        
        for (id, trackData) in nsdict.object(forKey: "Tracks") as! NSDictionary {
            let trackData = trackData as! NSDictionary
            
            let track = Track()
            
            track.id = Int(id as! String)!
            track.title = trackData["Name"] as? String
            track.author = trackData["Artist"] as? String
            track.album = trackData["Album"] as? String
            track.path = trackData["Location"] as? String
            
            database[Int(id as! String)!] = track
        }
        
        var playlistDatabase: [String: Playlist]! = [:]
        let masterPlaylist = Playlist(folder: true)

        for playlistData in nsdict.object(forKey: "Playlists") as! NSArray {
            let playlistData = playlistData as! NSDictionary
            if playlistData.object(forKey: "Master") as? Bool ?? false {
                continue
            }
            
            let isFolder = playlistData.object(forKey: "Folder") as? Bool ?? false
            let playlist = Playlist(folder: isFolder)
            
            playlist.name = playlistData.object(forKey: "Name") as! String
            playlist.id = playlistData.object(forKey: "Playlist Persistent ID") as! String
            
            if !isFolder {
                for trackData in playlistData.object(forKey: "Playlist Items") as? NSArray ?? [] {
                    let trackData = trackData as! NSDictionary
                    let id = trackData["Track ID"] as! Int
                    playlist.tracks.append(database[id]!)
                }
            }
            
            if let parent = playlistData.object(forKey: "Parent Persistent ID") as? String {
                playlistDatabase[parent]?.add(child: playlist)
            }
            else {
                masterPlaylist.add(child: playlist)
            }
            
            playlistDatabase[playlist.id] = playlist
        }
        
        return (database, masterPlaylist)
    }
}
