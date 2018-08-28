//
//  PlaylistProtocol.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol PlaylistProtocol : class {
    var tracksList: [Track] { get }
    var name: String { get }
    
    func convert(to: NSManagedObjectContext) -> Self?
}

enum ModifyingAction {
    case add, delete, reorder
}

protocol ModifiablePlaylist : PlaylistProtocol {
    func supports(action: ModifyingAction) -> Bool
    
    func confirm(action: ModifyingAction) -> Bool
    
    func addTracks(_ tracks: [Track], above: Int?)
    
    func removeTracks(_ tracks: [Track])
}

extension ModifiablePlaylist {
    func confirm(action: ModifyingAction) -> Bool {
        return true
    }
    
    func addTracks(_ tracks: [Track], above: Int? = nil) {
        addTracks(tracks, above: above)
    }
    
    func removeTracks(_ tracks: [Track]) {
        
    }
}
