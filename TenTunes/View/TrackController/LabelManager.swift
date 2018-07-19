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

class LabelManager : NSObject, LabelFieldDelegate {
    @IBOutlet @objc weak open var delegate: LabelManagerDelegate?
    
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

        groups.append(LabelGroup(title: "Has Tag", contents: playlistResults(search: compareSubstring, tag: true)))
        groups.append(LabelGroup(title: "In Playlist", contents: playlistResults(search: compareSubstring, tag: false)))

        return groups
    }
    
    func playlistResults(search: String, tag: Bool) -> [PlaylistLabel] {
        let found = search.count > 0 ? (tag ? tags : playlists).filter({ $0.name.lowercased().range(of: search) != nil }) : playlists
        let sortedPlaylists = found.map({ PlaylistLabel(playlist: $0, isTag: tag) }).sorted { (a, b) -> Bool in
            a.representation.count < b.representation.count
        }
        return sortedPlaylists
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
        
        if let labelField = obj.object as? LabelTextField {
            let editing = labelField.editingString
            if editing.count > 0 {
                labelField.autocomplete(with: LabelSearch(string: labelField.editingString))
            }
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        let labelField = control as! LabelTextField
        
        if commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
            // Use the first matching tag
            let compareSubstring = labelField.editingString.lowercased()
            
            let applicable = playlistResults(search: compareSubstring, tag: true)
            if let tag = applicable.first {
                labelField.autocomplete(with: tag)
                return true
            }
        }
        
        return false
    }
}
