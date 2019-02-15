//
//  Library+ExportLibrary.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 15.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension Library.Export {
    @discardableResult
    func remoteLibrary(_ rawPlaylists: [Playlist], to url: URL, pather: @escaping (Track, URL) -> String?) -> Library? {
        guard let other = Library(name: "TenTunes", at: url, create: true) else {
            return nil
        }
        
        let tracks = rawPlaylists.flatMap {
            $0.tracksList
        }.uniqueElements
        
        let playlists: [Playlist] = [library.masterPlaylist].flatten {
            ($0 as? PlaylistFolder)?.childrenList
        }.filter(rawPlaylists.contains)
        
        // Old to New
        var otherTracks: [Track: Track] = [:]
        for track in tracks {
            if let otherTrack = convert(track, toLibrary: other, pather: pather) {
                otherTracks[track] = otherTrack
            }
        }
        
        // Old to New
        var otherPlaylists: [Playlist: Playlist] = [:]
        for playlist in playlists {
            if let otherPlaylist = convert(playlist, toLibrary: other,
                                           trackMapper: otherTracks,
                                           playlistMapper: &otherPlaylists) {
                otherPlaylists[playlist] = otherPlaylist
            }
        }
        
        try? other.viewContext.save()
        
        return other
    }
    
    func convert(_ track: Track, toLibrary other: Library, pather: @escaping (Track, URL) -> String?) -> Track? {
        guard let otherTrack = track.resolvedURL ?=> other.import().track else {
            return nil
        }

        // Non-Copyable
        otherTrack.creationDate = track.creationDate
        otherTrack.path = pather(track, other.directory)

        // Shortcut
        otherTrack.title = track.title
        otherTrack.album = track.album
        otherTrack.author = track.author

        otherTrack.key = track.key
        otherTrack.bpmString = track.bpmString

        otherTrack.artworkData = track.artworkData
        otherTrack.analysisData = track.analysisData

        return otherTrack
    }

    func convert(_ playlist: Playlist, toLibrary other: Library, trackMapper: [Track: Track], playlistMapper: inout [Playlist: Playlist]) -> Playlist? {
        var otherPlaylist: Playlist? = nil
        
        if let playlist = playlist as? PlaylistManual {
            let newPlaylist = PlaylistManual(context: other.viewContext)
            
            newPlaylist.addTracks(playlist.tracksList.compactMap {
                trackMapper[$0]
            })
            
            otherPlaylist = newPlaylist
        }
        else if let playlist = playlist as? PlaylistCartesian {
            let newPlaylist = PlaylistCartesian(context: other.viewContext)
            
            newPlaylist.rules = NSKeyedArchiver.clone(playlist.rules)!
            
            otherPlaylist = newPlaylist
        }
        else if let playlist = playlist as? PlaylistSmart {
            let newPlaylist = PlaylistSmart(context: other.viewContext)
            
            newPlaylist.rules = NSKeyedArchiver.clone(playlist.rules)!
            
            otherPlaylist = newPlaylist
        }
        else if playlist is PlaylistFolder {
            let newPlaylist = PlaylistFolder(context: other.viewContext)
            
            otherPlaylist = newPlaylist
        }
        
        guard let newPlaylist = otherPlaylist else {
            return nil
        }
        
        playlistMapper[playlist] = newPlaylist
        
        newPlaylist.name = playlist.name
        newPlaylist.creationDate = playlist.creationDate
        newPlaylist.iTunesID = playlist.iTunesID

        if let parent = playlistMapper[playlist.parent!] as? PlaylistFolder {
            parent.addToChildren(newPlaylist)
        }
        else {
            other.masterPlaylist.addToChildren(newPlaylist)
        }

        return newPlaylist
    }
}
