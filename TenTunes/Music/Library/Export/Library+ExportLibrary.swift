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
        
        let masterPlaylist = library.masterPlaylist.convert(to: context)!
        
        let tracks = rawPlaylists.flatMap {
            $0.tracksList
        }.uniqueElements
        
        var implicityIncludedPlaylists = Set(rawPlaylists.flatten { $0.path })
        implicityIncludedPlaylists.remove(masterPlaylist)
        
        // Sort by their tree rep so we always have parents first
        let playlists: [Playlist] = [masterPlaylist].flatten {
            ($0 as? PlaylistFolder)?.childrenList
        }.filter(implicityIncludedPlaylists.contains)
        
        let otherContext = other.newChildBackgroundContext()
        otherContext.performAndWait {
            let remote = RemoteLibrary(src: library, dst: other, context: otherContext, pather: pather)

            for track in tracks {
                remote.convert(track)
            }
            
            for playlist in playlists {
                remote.convert(playlist)
            }

            try! otherContext.save()
        }
        
        do {
            try other.viewContext.save()
        }
        catch {
            print("Error saving remote library: ")
            print(error)
        }
        
        return other
    }
    
    class RemoteLibrary {
        let src: Library
        let dst: Library
        
        let context: NSManagedObjectContext
        
        let pather: (Track, URL) -> String?
        var tracks: [Track: Track] = [:]
        var playlists: [Playlist: Playlist] = [:]

        init(src: Library, dst: Library, context: NSManagedObjectContext, pather: @escaping (Track, URL) -> String?) {
            self.src = src
            self.dst = dst
            self.context = context
            self.pather = pather
        }
        
        @discardableResult
        func convert(_ track: Track) -> Track? {
            guard let otherTrack = track.resolvedURL ?=> dst.import(context).track else {
                return nil
            }
            
            // Non-Copyable
            otherTrack.creationDate = track.creationDate
            otherTrack.path = pather(track, dst.directory)
            
            // Shortcut
            otherTrack.title = track.title
            otherTrack.album = track.album
            otherTrack.author = track.author
            
            otherTrack.key = track.key
            otherTrack.bpmString = track.bpmString
            otherTrack.durationR = track.durationR
            
            otherTrack.forcedVisuals.analysis = track.visuals?.analysis
            otherTrack.forcedVisuals.artworkPreview = track.artworkPreview
            
            tracks[track] = otherTrack
            
            return otherTrack
        }
        
        @discardableResult
        func convert(_ playlist: Playlist) -> Playlist? {
            var otherPlaylist: Playlist? = nil
            
            if let playlist = playlist as? PlaylistManual {
                let newPlaylist = PlaylistManual(context: context)
                
                newPlaylist.addTracks(playlist.tracksList.compactMap {
                    tracks[$0]
                })
                
                otherPlaylist = newPlaylist
            }
            else if let playlist = playlist as? PlaylistCartesian {
                let newPlaylist = PlaylistCartesian(context: context)
                
                // TODO Adjust IDs of tokens to new library
                newPlaylist.rules = NSKeyedArchiver.clone(playlist.rules)!
                
                otherPlaylist = newPlaylist
            }
            else if let playlist = playlist as? PlaylistSmart {
                let newPlaylist = PlaylistSmart(context: context)
                
                // TODO Adjust IDs of tokens to new library
                newPlaylist.rules = NSKeyedArchiver.clone(playlist.rules)!
                
                otherPlaylist = newPlaylist
            }
            else if playlist is PlaylistFolder {
                let newPlaylist = PlaylistFolder(context: context)
                
                otherPlaylist = newPlaylist
            }
            
            guard let newPlaylist = otherPlaylist else {
                return nil
            }
            
            playlists[playlist] = newPlaylist
            
            newPlaylist.name = playlist.name
            newPlaylist.creationDate = playlist.creationDate
            newPlaylist.iTunesID = playlist.iTunesID
            
            let parent = (playlists[playlist.parent!] as? PlaylistFolder)
                ?? dst.masterPlaylist.convert(to: context)!
            parent.addToChildren(newPlaylist)
            
            return newPlaylist
        }
    }
}
