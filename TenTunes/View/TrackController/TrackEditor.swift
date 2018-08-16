//
//  FileTagEditor.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class TrackEditor: NSViewController {
        
    var context: NSManagedObjectContext!
    @objc dynamic var tracks: [Track] = [] {
        didSet {
            for track in tracks {
                try! track.fetchMetadata()
            }
            
            Library.shared.mediaLocation.updateLocations(of: tracks)
        }
    }
    @IBOutlet var tracksController: NSArrayController!
    
    var manyTracks: [Track] = []
    
    @IBOutlet var _contentView: NSView!
    @IBOutlet var _manyPlaceholder: NSView!
    @IBOutlet var _errorPlaceholder: NSView!
    @IBOutlet var _errorTextField: NSTextField!
    
    @IBOutlet var _tagEditor: LabelTextField!
    
    override func viewDidLoad() {
        showError(text: "No Tracks Selected")
    }
    
    func findShares<T : Hashable>(in ts: [Set<T>]) -> (Set<T>, Set<T>) {
        guard !ts.isEmpty else {
            return (Set(), Set())
        }
        
        return ts.dropFirst().reduce((Set(), ts.first!)) { (acc, t) in
            var (omitted, shared) = acc
            
            omitted = omitted.union(t.symmetricDifference(shared))
            shared = shared.intersection(t)
            
            return (omitted, shared)
        }
    }
    
    func present(tracks: [Track]) {
        if tracks.count == 0 {
            showError(text: "No Tracks Selected")
        }
        else if tracks.contains(where: { $0.url == nil }) {
            showError(text: "Tracks Not Found")
        }
        else if tracks.count < 2 {
            show(tracks: tracks)
        }
        else {
            suggest(tracks: tracks)
        }
    }
    
    func show(tracks: [Track]) {
        context = Library.shared.newConcurrentContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy // User is always right
        self.tracks = context.compactConvert(tracks)
        
        let (omittedTags, sharedTags) = findShares(in: self.tracks.map { $0.tags })
        _tagEditor.objectValue = (omittedTags.count > 0 ? [omittedTags] as [AnyObject] : [])
            + (sharedTags.sorted { $0.name < $1.name } as [AnyObject])
        
        view.setFullSizeContent(_contentView)
    }
    
    func showError(text: String) {
        _errorTextField.stringValue = text
        view.setFullSizeContent(_errorPlaceholder)
    }
    
    func suggest(tracks: [Track]) {
        manyTracks = tracks
        
        view.setFullSizeContent(_manyPlaceholder)
    }
    
    @IBAction func save(_ sender: Any) {
        for track in tracks {
            // Don't call the collection method since it auto-saves in the wrong context
            Library.shared.mediaLocation.updateLocation(of: track)
        }
        
        try! context.save()

        for track in tracks {
            track.writeMetadata()
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
    }
    
    @IBAction func showSuggestedTracks(_ sender: Any) {
        show(tracks: manyTracks)
    }
}

extension TrackEditor : LabelFieldDelegate {
    func tagResults(search: String, exact: Bool = false) -> [PlaylistManual] {
        return Library.shared.allTags(in: context).of(type: PlaylistManual.self).filter { exact ? $0.name.lowercased() == search : $0.name.lowercased().range(of: search) != nil }
            .sorted { (a, b) in a.name.count < b.name.count }
    }
    
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [LabelGroup]? {
        let compareSubstring = substring.lowercased()
        var groups: [LabelGroup] = []
        
        groups.append(LabelGroup(title: "Tag", contents: tagResults(search: compareSubstring)))
        
        return groups
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as? PlaylistManual)?.name ?? "<Multiple Values>"
    }
    
    func tokenFieldChangedLabels(_ tokenField: NSTokenField, labels: [Any]) {
        let allowedOthers = labels.of(type: Set<PlaylistManual>.self).first ?? Set()
        let newTags = Set(labels.of(type: PlaylistManual.self))
        
        for track in tracks where track.tags != newTags {
            track.tags = newTags.union(track.tags.intersection(allowedOthers))
        }
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        // TODO Hack, let LabelTextField observe this instead
        (obj.object as! LabelTextField).controlTextDidChange(obj)
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        return tokens.compactMap {
            guard let compareSubstring = ($0 as? String)?.lowercased() else {
                return $0
            }
            
            if let match = tagResults(search: compareSubstring, exact: true).first {
                return match
            }
            
            // Must create a new one
            // TODO
            return nil
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        let labelField = control as! LabelTextField
        
        if commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
            // Use the first matching tag
            let compareSubstring = labelField.editingString.lowercased()
            
            let applicable = tagResults(search: compareSubstring)
            if let tag = applicable.first {
                labelField.autocomplete(with: tag)
                return true
            }
        }
        
        return false
    }
}
