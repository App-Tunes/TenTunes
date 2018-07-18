//
//  LabelDelegate.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 18.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc protocol LabelManagerDelegate {
    func labelsChanged(labels: [Label])
}

@objc protocol Label {
    func filter(tracks: [Track]) -> [Track]
    
    var representation: String { get }
}

class LabelTag : Label {
    var tag: String
    
    init(tag: String) {
        self.tag = tag
    }
    
    func filter(tracks: [Track]) -> [Track] {
        return []
    }
    
    var representation: String {
        return tag
    }
}

class PlaylistLabel : Label {
    var playlist: Playlist?
    
    init(playlist: Playlist?) {
        self.playlist = playlist
    }
    
    func filter(tracks: [Track]) -> [Track] {
        guard let playlist = playlist else {
            return []
        }
        
        return tracks.filter(playlist.tracksList.contains)
    }
    
    var representation: String {
        return "In: " + (playlist?.name ?? "Invalid Playlist")
    }
}

class LabelManager : NSObject, LabelFieldDelegate {
    @IBOutlet
    // TODO Weak?
    @objc var delegate: LabelManagerDelegate?
    
    var playlists: [Playlist] {
        return Library.shared.allPlaylists
    }
    
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [LabelGroup]? {
        let compareSubstring = substring.lowercased()
        
        var groups: [LabelGroup] = [LabelGroup(title: "Has Tag", contents: ["tag:" + substring])]

        let found = substring.count > 0 ? playlists.filter({ $0.name.lowercased().range(of: compareSubstring) != nil }) : playlists
        groups.append(LabelGroup(title: "In Playlist", contents: found.map { "in:" + Library.shared.writePlaylistID(of: $0) }))

        return groups
    }
    
    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any? {
        if editingString.starts(with: "in:") {
            let playlist = Library.shared.restoreFrom(playlistID: editingString[3...])
            return PlaylistLabel(playlist: playlist)
        }
        else if editingString.starts(with: "tag:") {
            return LabelTag(tag: editingString[4...])
        }
        
        return nil
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as? Label)?.representation
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        // TODO Hack, let LabelTextField observe this instead
        (obj.object as! LabelTextField).controlTextDidChange(obj)
    }
}
