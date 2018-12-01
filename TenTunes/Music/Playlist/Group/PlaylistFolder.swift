//
//  PlaylistFolder+CoreDataClass.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData

@objc(PlaylistFolder)
public class PlaylistFolder: Playlist {    
    public override func awakeFromInsert() {
        if name == "" {
            name = "Unnamed Group"
        }

        super.awakeFromInsert()
    }

    var childrenList: [Playlist] {
        get { return Array(children) as! [Playlist] }
        set { children = NSOrderedSet(array: newValue) }
    }
    
    func addPlaylist(_ playlist: Playlist, above: Int?) {
        addToChildren(playlist)
        
        if let above = above {
            children = children.rearranged(elements: [playlist], to: above)
        }
    }
    
    var automatesChildren: Bool {
        return false
    }
    
    override func _freshTracksList(rguard: RecursionGuard<Playlist>) -> [Track] {
        return rguard.protected(self) {
            return self.childrenList.flatMap { $0.guardedTracksList(rguard: rguard) } .uniqueElements
        } ?? []
    }
    
    override var isTrivial: Bool { return children.count == 0 }
    
    override var icon: NSImage {
        return #imageLiteral(resourceName: "folder")
    }
}

extension PlaylistFolder : ModifiablePlaylist {
    var modifableChildrenList: [ModifiablePlaylist]? {
        return childrenList as? [ModifiablePlaylist]
    }
    
    func _supports(action: ModifyingAction, rguard: RecursionGuard<Playlist>) -> Bool {
        // Can only delete, if we want to add then what do we even add to??
        guard action == .delete else {
            return false
        }
        
        return rguard.protected(self) {
            return self.modifableChildrenList?.allSatisfy { $0.supports(action: action) } ?? false
        } ?? false
    }
    
    func confirm(action: ModifyingAction) -> Bool {
        switch action {
        case .delete:
            return NSAlert.confirm(action: "Remove from all playlists", text: "The tracks will be removed from all playlists in this group (\( modifableChildrenList!.count )).")
        default:
            return true
        }
    }
    
    func removeTracks(_ tracks: [Track]) {
        for playlist in modifableChildrenList! {
            playlist.removeTracks(tracks)
        }
    }
}
