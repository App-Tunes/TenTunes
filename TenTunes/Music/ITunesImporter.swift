//
//  ITunesImporter.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 24.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class ITunesImporter {
    static func parse(url: URL) -> Library? {
        guard let nsdict = NSDictionary(contentsOf: url) else {
            return nil
        }
        
        let library = Library()
        
        for (id, trackData) in nsdict.object(forKey: "Tracks") as! NSDictionary {
            let trackData = trackData as! NSDictionary
            
            let track = Track()
            
            track.id = Int(id as! String)!
            track.title = trackData["Name"] as? String
            track.author = trackData["Artist"] as? String
            track.album = trackData["Album"] as? String
            track.path = trackData["Location"] as? String
            
            library.addTrackToLibrary(track)
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
            let playlist = Playlist(folder: isFolder)
            
            playlist.name = playlistData.object(forKey: "Name") as! String
            playlist.id = playlistData.object(forKey: "Playlist Persistent ID") as! String
            
            if !isFolder {
                for trackData in playlistData.object(forKey: "Playlist Items") as? NSArray ?? [] {
                    let trackData = trackData as! NSDictionary
                    let id = trackData["Track ID"] as! Int
                    playlist.tracks.append(library.track(byId: id)!)
                }
            }
            
            if let parent = playlistData.object(forKey: "Parent Persistent ID") as? String {
                library.addPlaylist(playlist, to: library.playlist(byId: parent)!)
            }
            else {
                library.addPlaylist(playlist)
            }
        }
        
        return library
    }
}
