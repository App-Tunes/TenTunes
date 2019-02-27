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
        return rguard.protected(self) {
            let all = Library.shared.allTracks.convert(to: managedObjectContext!)!.tracksList
            return all.filter(filter(in: managedObjectContext!, rguard: rguard) ?? SmartPlaylistRules.trivial)
        } ?? []
    }
        
    func filter(in context: NSManagedObjectContext, rguard: RecursionGuard<Playlist>) -> ((Track) -> Bool)? {
        return rrules.filter(in: context, rguard: rguard)
    }
    
    override var isTrivial: Bool { return rules?.tokens.isEmpty ?? true }
    
    override var icon: NSImage {
        return #imageLiteral(resourceName: "playlist-smart")
    }
}

extension PlaylistSmart : ModifiablePlaylist {
    func _supports(action: ModifyingAction, rguard: RecursionGuard<Playlist>) -> Bool {
        // Add to all on all add, remove from all on any delete
        guard (action == .add && rrules.mode == .all) || (action == .delete && rules.mode == .any) else {
            return false
        }
        
        let conform = action == .add
        
        return rguard.protected(self) {
            return rrules.tokens.allSatisfy {
                self.canSetConformity(of: $0, to: conform, rguard: rguard)
            }
        } ?? false
    }
    
    func confirm(action: ModifyingAction) -> Bool {
        switch action {
        case .add:
            return NSAlert.confirm(action: "Add to smart playlist", text: "The tracks will be added to this playlist by conforming to all its rules (\( rrules.tokens.count )).")
        case .delete:
            return NSAlert.confirm(action: "Remove from all playlists", text: "The tracks will be removed from this playlist by ceising to conform to all its rules (\( rrules.tokens.count )).")
        default:
            return false
        }
    }
    
    func addTracks(_ tracks: [Track], above: Int?) {
        if above != nil {
            fatalError("Reorder not supported")
        }
        
        for token in rrules.tokens {
            set(tracks: tracks, toConform: true, toToken: token)
        }
    }
    
    func removeTracks(_ tracks: [Track]) {
        for token in rrules.tokens {
            set(tracks: tracks, toConform: false, toToken: token)
        }
    }
    
    func canSetConformity(of token: SmartPlaylistRules.Token, to conform: Bool, rguard: RecursionGuard<Playlist>) -> Bool {
        if let playlistToken = token as? SmartPlaylistRules.Token.InPlaylist {
            guard let playlist = playlistToken.playlist(in: managedObjectContext!) as? ModifiablePlaylist else {
                return false
            }
            
            return conform == token.not
                ? playlist._supports(action: .delete, rguard: rguard)
                : playlist._supports(action: .add, rguard: rguard)
        }
        
        return false
    }
    
    func set(tracks: [Track], toConform conform: Bool, toToken token: SmartPlaylistRules.Token) {
        if let playlistToken = token as? SmartPlaylistRules.Token.InPlaylist {
            guard let playlist = playlistToken.playlist(in: managedObjectContext!) as? ModifiablePlaylist else {
                return
            }
            
            if conform == token.not {
                playlist.removeTracks(tracks)
            }
            else {
                playlist.addTracks(tracks)
            }
        }
    }
}
