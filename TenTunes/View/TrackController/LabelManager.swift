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
    func filter() -> (Track) -> Bool
    
    var representation: String { get }
}

class LabelTag : Label {
    var tag: String
    
    init(tag: String) {
        self.tag = tag
    }
    
    func filter() -> (Track) -> Bool {
        return { _ in return false }
    }
    
    var representation: String {
        return "Search: " + tag
    }
}

class LabelSearch : Label {
    var string: String
    
    init(string: String) {
        self.string = string
    }
    
    func filter() -> (Track) -> Bool {
        return PlayHistory.filter(findText: string)!
    }
    
    var representation: String {
        return string
    }
}

class PlaylistLabel : Label {
    var playlist: Playlist?
    
    init(playlist: Playlist?) {
        self.playlist = playlist
    }
    
    func filter() -> (Track) -> Bool {
        guard let tracks = playlist?.tracksList else {
            return { _ in return false }
        }

        return { track in
            return (tracks.map { $0.objectID } ).contains(track.objectID)
        }
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
        
        var groups: [LabelGroup] = [
            LabelGroup(title: "Search For", contents: [LabelSearch(string: substring)]),
            LabelGroup(title: "Has Tag", contents: [LabelTag(tag: substring)])
        ]

        let found = substring.count > 0 ? playlists.filter({ $0.name.lowercased().range(of: compareSubstring) != nil }) : playlists
        groups.append(LabelGroup(title: "In Playlist", contents: found.map { PlaylistLabel(playlist: $0) }))

        return groups
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as? Label)?.representation
    }
    
    func tokenField(_ tokenField: NSTokenField, editingStringForRepresentedObject representedObject: Any) -> String? {
        if let label = representedObject as? LabelTag {
            return "tag:" + label.tag
        }
        else if let label = representedObject as? PlaylistLabel {
            return "in:\(String(describing: label.playlist?.objectID))"
        }
        
        return nil
    }
    
    func tokenFieldChangedLabels(_ tokenField: NSTokenField, labels: [Any]) {
        delegate?.labelsChanged(labels: labels as! [Label])
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        // TODO Hack, let LabelTextField observe this instead
        (obj.object as! LabelTextField).controlTextDidChange(obj)
    }
}
