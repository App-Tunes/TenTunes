//
//  PlaylistSmart+CoreDataClass.swift
//  
//
//  Created by Lukas Tenbrink on 19.07.18.
//
//

import Foundation
import CoreData

@objc(PlaylistSmart)
public class PlaylistSmart: Playlist {
    override func _freshTracksList(rguard: RecursionGuard<Playlist>) -> [Track] {
        guard rguard.push(self) else {
            return []
        }
        
        let all = Library.shared.allTracks.convert(to: managedObjectContext!)!.tracksList
        let tracks = all.filter(filter(in: managedObjectContext!, rguard: rguard))
        
        rguard.pop(self)
        
        return tracks
    }
        
    func filter(in context: NSManagedObjectContext, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
        return rrules.filter(in: context, rguard: rguard)
    }
    
    override var icon: NSImage {
        return #imageLiteral(resourceName: "playlist-smart")
    }
}

extension PlaylistSmart : ModifiablePlaylist {
    var modifableTokenPlaylists: [ModifiablePlaylist]? {
        guard let playlistTokens = rrules.tokens as? [SmartPlaylistRules.Token.InPlaylist] else {
            return nil
        }
        
        return playlistTokens.map({ $0.playlist(in: self.managedObjectContext!) }) as? [ModifiablePlaylist]
    }
    
    func supports(action: ModifyingAction) -> Bool {
        // Add to all on all add, remove from all on any delete
        guard (action == .add && !rrules.any) || (action == .delete && rules.any) else {
            return false
        }
        
        return modifableTokenPlaylists?.allMatch { $0.supports(action: action) } ?? false
    }
    
    func confirm(action: ModifyingAction) -> Bool {
        switch action {
        case .add:
            return NSAlert.confirm(action: "Add to all playlists", text: "The tracks will be added to all playlists that are part of this playlists' rules (\( modifableTokenPlaylists!.count )).")
        case .delete:
            return NSAlert.confirm(action: "Remove from all playlists", text: "The tracks will be removed from all playlists that are part of this playlists' rules (\( modifableTokenPlaylists!.count )).")
        default:
            return true
        }
    }
    
    func addTracks(_ tracks: [Track], above: Int?) {
        if above != nil {
            fatalError("Reorder not supported")
        }
        
        for playlist in modifableTokenPlaylists! {
            playlist.addTracks(tracks, above: nil)
        }
    }
    
    func removeTracks(_ tracks: [Track]) {
        for playlist in modifableTokenPlaylists! {
            playlist.removeTracks(tracks)
        }
    }
}
