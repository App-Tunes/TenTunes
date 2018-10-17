//
//  PlaylistMultiple.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.09.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class PlaylistMultiple : PlaylistProtocol {
    let playlists: [PlaylistProtocol]
    
    required init(playlists: [PlaylistProtocol]) {
        self.playlists = playlists
    }
    
    var name: String {
        return playlists.map { $0.name }.joined(separator: ", ")
    }
    
    var tracksList: [Track] {
        return playlists.flatMap { $0.tracksList }.uniqueElements
    }
    
    func convert(to: NSManagedObjectContext) -> Self? {
        let converted = playlists.compactMap { $0.convert(to: to) }
        return converted.count == playlists.count ? type(of: self).init(playlists: converted) : nil
    }
}

extension PlaylistMultiple : ModifiablePlaylist {
    var modifablePlaylists: [ModifiablePlaylist]? {
        return playlists as? [ModifiablePlaylist]
    }
    
    func _supports(action: ModifyingAction, rguard: RecursionGuard<Playlist>) -> Bool {
        // Can only delete, if we want to add then what do we even add to??
        guard action == .delete else {
            return false
        }
        
        return self.modifablePlaylists?.allSatisfy { $0.supports(action: action) } ?? false
    }
    
    func confirm(action: ModifyingAction) -> Bool {
        switch action {
        case .delete:
            return NSAlert.confirm(action: "Remove from all playlists", text: "The tracks will be removed from all playlists in this selection (\( modifablePlaylists!.count )).")
        default:
            return true
        }
    }
    
    func removeTracks(_ tracks: [Track]) {
        for playlist in modifablePlaylists! {
            playlist.removeTracks(tracks)
        }
    }
}

