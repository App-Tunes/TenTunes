//
//  TrackEditor+Tags.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.08.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension TagEditor : TTTokenFieldDelegate {
    var viewTags : [ViewableTag] {
        return outlineView.children(ofItem: masterItem) as! [ViewableTag]
    }
        
    static func desiredTagTokens(tracks: [Track]) -> [ViewableTag] {
        let (omittedTags, sharedTags) = Set.shares(in: tracks.map { $0.tags })
        let (omittedRelations, sharedRelations) = Set.shares(in: tracks.map { $0.relatedTracksSet })
        
        let omissions = (omittedTags as Set<NSManagedObject>).union(omittedRelations)
        let omittedPart : [ViewableTag] = omissions.isEmpty ? [] : [.many(items: omissions)]
        
        return omittedPart
            + sharedRelations.sorted { $0.rTitle < $1.rTitle }.map { .related(track: $0) }
            + sharedTags.sorted { $0.name < $1.name }.map { .tag(playlist: $0) }
    }

    func tagResults(search: String, exact: Bool = false, onlyRelevant: Bool = true) -> [PlaylistManual] {
        var tags = Library.shared.allTags(in: context).of(type: PlaylistManual.self).filter {
            exact
                ? $0.name.lowercased() == search.lowercased()
                : $0.name.range(of: search, options: [.diacriticInsensitive, .caseInsensitive]) != nil
            }
            
        if onlyRelevant {
            tags = tags.filter { !tagTokens.caseLet(ViewableTag.tag).contains($0) }
        }
        
        return tags.sorted { (a, b) in a.name.count < b.name.count }
    }
    
    func trackResults(search: String) -> [Track] {
        return Library.shared.allTracks().filter {
                $0.rTitle.range(of: search, options: [.diacriticInsensitive, .caseInsensitive]) != nil
            }
            .filter { !self.tracks.contains($0) }
            .filter { !tagTokens.caseLet(ViewableTag.related).contains($0) }
            .sorted { (a, b) in a.rTitle.count < b.rTitle.count }
    }
    
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [TTTokenField.TokenGroup]? {
        var groups: [TTTokenField.TokenGroup] = []
        
        groups.append(.init(title: "Tag", contents: tagResults(search: substring)))
        groups.append(.init(title: "Track", contents: trackResults(search: substring)))

        return groups
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        if let track = representedObject as? Track {
            return track.rTitle // Special case for adding tracks
        }
        
        return (representedObject as? PlaylistManual)?.name ?? "<Multiple Values>"
    }
    
    func tokenField(_ tokenField: NSTokenField, changedTokens tokens: [Any]) {
        let tokenField = tokenField as! TTTokenField
        
        // TODO Make the token fields themselves use ViewableTag
        let newSharedRelations = tokenField.items.compactMap {
            if let track = $0 as? Track {
                return ViewableTag.related(track: track)
            }
            else if let playlist = $0 as? PlaylistManual {
                return ViewableTag.tag(playlist: playlist)
            }
            
            return nil
        }.filter {
            Enumerations.is($0, ofType: ViewableTag.related) || Enumerations.is($0, ofType: ViewableTag.tag)
        }
        
        guard newSharedRelations.count > 0 else {
            return
        }
        
        let addTags = newSharedRelations.filter { !tagTokens.contains($0) }
        tagTokens.append(contentsOf: addTags)
        
        if case .many(var omitted) = tagTokens[0] {
            let a: [PlaylistManual] = newSharedRelations.caseLet(ViewableTag.tag)
            omitted.remove(contentsOf: Set(a))
            let b: [Track] = newSharedRelations.caseLet(ViewableTag.related)
            omitted.remove(contentsOf: Set(b))

            if omitted.isEmpty {
                tagTokens.remove(at: 0)
                // Hax but multiple values are always the first, and remove by item doesn't work because it's an array (copy by value)
                outlineView.removeItems(at: IndexSet(integer: 0), inParent: masterItem, withAnimation: .slideDown)
            }
            else {
                tagTokens[0] = .many(items: omitted)
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
        let sharedRelations = Set(showedTokens.caseLet(ViewableTag.related))

        for track in tracks {
            let oldTrackTags = track.tags
            let newTags = sharedTags.union(oldTrackTags.intersection(allowedOthers.of(type: PlaylistManual.self)))
            if newTags != oldTrackTags { track.tags = newTags }

            let oldTrackRelations = track.relatedTracksSet
            let newRelations = sharedRelations.union(oldTrackRelations.intersection(allowedOthers.of(type: Track.self)))
            if newRelations != oldTrackRelations { track.relatedTracksSet = newRelations }
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        return tokens.compactMap {
            guard let string = $0 as? String else {
                return $0
            }
            
            if let match = tagResults(search: string, exact: true, onlyRelevant: false).first {
                return match
            }
            
            // Must create a new one
            if NSAlert.confirm(action: "Create New Tag", text: "The tag '\(string)' is unknown. Do you want to create it?") {
                let newTag = PlaylistManual(context: Library.shared.viewContext)
                newTag.name = string
                Library.shared[PlaylistRole.tags].addToChildren(newTag)
                
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
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let labelField = obj.object as? TTTokenField {
            labelField.objectValue = [] // Clear instead of letting it become a Token
        }
    }
}
