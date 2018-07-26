//
//  LabelDelegate.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 18.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc protocol TrackLabelControllerDelegate {
    @objc optional func labelsChanged(trackLabelController: TrackLabelController, labels: [TrackLabel])
    
    @objc optional func editingEnded(labelManager: TrackLabelController, notification: Notification)
}

class TrackLabelController : NSViewController, LabelFieldDelegate {
    @IBOutlet @objc weak open var delegate: TrackLabelControllerDelegate?
    
    @IBOutlet var _labelField: LabelTextField!
    
    @IBOutlet var _labelMenu: NSMenu!
    
    var currentLabels: [TrackLabel] {
        get { return _labelField.currentLabels as! [TrackLabel] }
        set { _labelField.currentLabels = newValue }
    }
    
    var playlists: [Playlist] {
        return Library.shared.allPlaylists().filter {
            !Library.shared.path(of: $0).contains(Library.shared.tagPlaylist)
        }
    }
    
    var tags: [Playlist] {
        return Library.shared.allPlaylists().filter {
            Library.shared.path(of: $0).contains(Library.shared.tagPlaylist) && $0 != Library.shared.tagPlaylist
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [LabelGroup]? {
        let compareSubstring = substring.lowercased()
        
        var groups: [LabelGroup] = [
            LabelGroup(title: "Search For", contents: [TrackLabel.Search(string: substring)]),
            ]
        
        if let int = Int(substring), int > 0 {
            groups.append(LabelGroup(title: "Kbps", contents: [
                TrackLabel.MinBitrate(bitrate: int, above: true),
                TrackLabel.MinBitrate(bitrate: int, above: false)
                ]))
        }
        
        groups.append(LabelGroup(title: "Has Tag", contents: playlistResults(search: compareSubstring, tag: true)))
        groups.append(LabelGroup(title: "Contained In Playlist", contents: playlistResults(search: compareSubstring, tag: false)))
        groups.append(LabelGroup(title: "Created By", contents: authorResults(search: compareSubstring)))
        groups.append(LabelGroup(title: "Released on Album", contents: albumResults(search: compareSubstring)))
        groups.append(LabelGroup(title: "Genre", contents: genreResults(search: compareSubstring)))
        
        return groups
    }
    
    static func sorted<L : TrackLabel>(labels: [L]) -> [L] {
        return labels.sorted { (a, b) -> Bool in
            a.representation(in: Library.shared.viewContext).count < b.representation(in: Library.shared.viewContext).count
        }
    }
    
    func genreResults(search: String) -> [TrackLabel.Genre] {
        let found = search.count > 0 ? Library.shared.allGenres.filter({ $0.lowercased().range(of: search) != nil }) : Library.shared.allGenres
        return TrackLabelController.sorted(labels: found.map { TrackLabel.Genre(genre: $0) })
    }
    
    func albumResults(search: String) -> [TrackLabel.InAlbum] {
        let found = search.count > 0 ? Library.shared.allAlbums.filter({ $0.title.lowercased().range(of: search) != nil }) : Library.shared.allAlbums
        return TrackLabelController.sorted(labels: found.map { TrackLabel.InAlbum(album: $0) })
    }
    
    func authorResults(search: String) -> [TrackLabel.Author] {
        let found = search.count > 0 ? Library.shared.allAuthors.filter({ $0.lowercased().range(of: search) != nil }) : Library.shared.allAuthors
        return TrackLabelController.sorted(labels: found.map { TrackLabel.Author(author: $0) })
    }
    
    func playlistResults(search: String, tag: Bool) -> [TrackLabel.InPlaylist] {
        let found = search.count > 0 ? (tag ? tags : playlists).filter({ $0.name.lowercased().range(of: search) != nil }) : playlists
        return TrackLabelController.sorted(labels: found.map({ TrackLabel.InPlaylist(playlist: $0, isTag: tag) }))
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as? TrackLabel)?.representation(in: Library.shared.viewContext)
    }
    
    func tokenFieldChangedLabels(_ tokenField: NSTokenField, labels: [Any]) {
        delegate?.labelsChanged?(trackLabelController: self, labels: labels as! [TrackLabel])
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        return tokens.map { $0 is TrackLabel ? $0 : TrackLabel.Search(string: $0 as! String) }
    }
    
    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        return !(representedObject is TrackLabel.Search)
    }
    
    func tokenField(_ tokenField: NSTokenField, menuForRepresentedObject representedObject: Any) -> NSMenu? {
        for item in _labelMenu.items { item.representedObject = representedObject }
        return _labelMenu
    }
    
    @IBAction func invertLabel(_ sender: Any) {
        let label = (sender as! NSMenuItem).representedObject as! TrackLabel
        let inverted = label.inverted()
        
        currentLabels[currentLabels.index(of: label)!] = inverted
        _labelField.notifyLabelChange()
        
        _labelField.reloadLabels()
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
                labelField.autocomplete(with: TrackLabel.Search(string: labelField.editingString))
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
