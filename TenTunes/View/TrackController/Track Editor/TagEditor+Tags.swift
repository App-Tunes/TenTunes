//
//  TrackEditor+Tags.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.08.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension TagEditor : TTTokenFieldDelegate {
    var viewTags : [Any] {
        return outlineView.children(ofItem: masterItem).compactMap { item in
            let view = outlineView.view(atColumn: 0, forItem: item, makeIfNecessary: false) as! NSTableCellView
            return view.textField!.objectValue as! [Any]
        }
    }
        
    static func desiredTagTokens(tracks: [Track]) -> [ViewableTag] {
        let (omittedTags, sharedTags) = Set.shares(in: tracks.map { $0.tags })
        let omittedPart : [ViewableTag] = omittedTags.isEmpty ? [] : [.many(playlists: omittedTags)]
        return omittedPart + sharedTags.sorted { $0.name < $1.name }.map { .tag(playlist: $0) }
    }

    func tagResults(search: String, exact: Bool = false) -> [PlaylistManual] {
        return Library.shared.allTags(in: context).of(type: PlaylistManual.self).filter {
            exact
                ? $0.name.lowercased() == search.lowercased()
                : $0.name.range(of: search, options: [.diacriticInsensitive, .caseInsensitive]) != nil
            }
            .filter { !tagTokens.caseLet(ViewableTag.tag).contains($0) } 
            .sorted { (a, b) in a.name.count < b.name.count }
    }
    
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [TTTokenField.TokenGroup]? {
        var groups: [TTTokenField.TokenGroup] = []
        
        groups.append(.init(title: "Tag", contents: tagResults(search: substring)))
        
        return groups
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as? PlaylistManual)?.name ?? "<Multiple Values>"
    }
    
    func tokenField(_ tokenField: NSTokenField, changedTokens tokens: [Any]) {
        let newTags = (tokenField.objectValue as! [Any]).of(type: PlaylistManual.self) // First might be multiple values
        
        guard newTags.count > 0 else {
            return
        }
        
        let existingTags = tagTokens.caseLet(ViewableTag.tag)
        
        let addTags = newTags.filter { !existingTags.contains($0) }
        tagTokens.append(contentsOf: addTags.map { .tag(playlist: $0) })
        
        if case .many(var omitted) = tagTokens[0] {
            omitted.remove(contentsOf: Set(newTags.of(type: PlaylistManual.self)))
            if omitted.isEmpty {
                tagTokens.remove(at: 0)
                // Little hacky but multiple values are always the first, and remove by item doesn't work because it's an array (copy by value)
                outlineView.removeItems(at: IndexSet(integer: 0), inParent: masterItem, withAnimation: .slideDown)
            }
            else {
                tagTokens[0] = .many(playlists: omitted)
            }
        }
        
        tokensChanged()
        
        outlineView.insertItems(at: IndexSet(integersIn: (outlineTokens.count - 2)..<(outlineTokens.count + addTags.count - 2)), inParent: masterItem, withAnimation: .slideDown)

        tokenField.objectValue = []
    }
    
    func tokensChanged() {
        let showedTokens = tagTokens
        let allowedOthers = showedTokens.caseLet(ViewableTag.many).first ?? Set()
        let sharedTags = Set(showedTokens.caseLet(ViewableTag.tag))
        
        for track in tracks {
            let new = sharedTags.union(track.tags.intersection(allowedOthers))
            if new != track.tags { track.tags = new }
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        return tokens.compactMap {
            guard let string = $0 as? String else {
                return $0
            }
            
            if let match = tagResults(search: string, exact: true).first {
                return match
            }
            
            // Must create a new one
            if NSAlert.confirm(action: "Create New Tag", text: "The tag '\(string)' is unknown. Do you want to create it?") {
                let newTag = PlaylistManual(context: Library.shared.viewContext)
                newTag.name = string
                Library.shared.tagPlaylist.addPlaylist(newTag)
                
                return newTag
            }
            
            return nil // Decide not to
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let labelField = control as? TTTokenField else {
            return false
        }
        
        if commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
            // Use the first matching tag
            if let tag = tagResults(search: labelField.editingString).first {
                labelField.autocomplete(with: tag)
            }

            // Always consume the alt enter
            return true
        }
        
        return false
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        if let labelField = obj.object as? TTTokenField {
            labelField.objectValue = [] // Clear instead of letting it become a Token
        }
    }
}
