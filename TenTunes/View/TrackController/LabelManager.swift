//
//  LabelDelegate.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 18.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc protocol LabelManagerDelegate {
    @objc optional func labelsChanged(labelManager: LabelManager, labels: [Label])

    @objc optional func editingEnded(labelManager: LabelManager, notification: Notification)
}

@objc protocol Label {
    func filter() -> (Track) -> Bool
    
    var representation: String { get }
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
        return "Search: " + string
    }
}

class PlaylistLabel : Label {
    var playlist: Playlist?
    var isTag: Bool
    
    init(playlist: Playlist?, isTag: Bool) {
        self.playlist = playlist
        self.isTag = isTag
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
        return (isTag ? "" : "In: ") + (playlist?.name ?? "Invalid Playlist")
    }
}

class LabelManager : NSObject, LabelFieldDelegate {
    @IBOutlet
    // TODO Weak?
    @objc var delegate: LabelManagerDelegate?
    
    var playlists: [Playlist] {
        return Library.shared.allPlaylists.filter {
            !Library.shared.path(of: $0).contains(Library.shared.tagPlaylist)
        }
    }
    
    var tags: [Playlist] {
        return Library.shared.allPlaylists.filter {
            Library.shared.path(of: $0).contains(Library.shared.tagPlaylist) && $0 != Library.shared.tagPlaylist
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [LabelGroup]? {
        let compareSubstring = substring.lowercased()
        
        var groups: [LabelGroup] = [
            LabelGroup(title: "Search For", contents: [LabelSearch(string: substring)]),
        ]

        let tags = substring.count > 0 ? self.tags.filter({ $0.name.lowercased().range(of: compareSubstring) != nil }) : playlists
        groups.append(LabelGroup(title: "Has Tag", contents: tags.map { PlaylistLabel(playlist: $0, isTag: true) }))

        let found = substring.count > 0 ? playlists.filter({ $0.name.lowercased().range(of: compareSubstring) != nil }) : playlists
        groups.append(LabelGroup(title: "In Playlist", contents: found.map { PlaylistLabel(playlist: $0, isTag: false) }))

        return groups
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as? Label)?.representation
    }
    
    func tokenFieldChangedLabels(_ tokenField: NSTokenField, labels: [Any]) {
        delegate?.labelsChanged?(labelManager: self, labels: labels as! [Label])
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        return tokens.map { $0 is Label ? $0 : LabelSearch(string: $0 as! String) }
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        // TODO Hack, let LabelTextField observe this instead
        (obj.object as! LabelTextField).controlTextDidChange(obj)
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        delegate?.editingEnded?(labelManager: self, notification: obj)
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        let labelField = control as! LabelTextField
        
        if commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
            // Use the first matching tag
            let compareSubstring = labelField.editingString.lowercased()
            
            let applicable = self.tags.filter({ $0.name.lowercased().range(of: compareSubstring) != nil })
            if let tag = applicable.first {
                labelField.autocomplete(with: PlaylistLabel(playlist: tag, isTag: true))
                return true
            }
        }
        
        return false
    }
}
