//
//  TagEditor.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol TagEditorDelegate {
    var tagEditorTracks: [Track] { get }
    var tagEditorOutline: NSOutlineView { get }
    var tagEditorMasterItem: AnyObject { get }
    var tagEditorContext: NSManagedObjectContext { get }
}

class TagEditor: NSObject {
    var delegate: TagEditorDelegate
    
    init(delegate: TagEditorDelegate) {
        self.delegate = delegate
    }
    
    var tagTokens : [ViewableTag] = []
    var outlineTokens : [ViewableTag] { return tagTokens + [.new] }
    
    var tracks: [Track] { return delegate.tagEditorTracks }
    var outlineView: NSOutlineView { return delegate.tagEditorOutline }
    var masterItem: AnyObject { return delegate.tagEditorMasterItem }
    var context: NSManagedObjectContext { return delegate.tagEditorContext }

    func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: Library.shared.viewContext)
    }
    
    @IBAction func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        
        if updates.of(type: Playlist.self).anySatisfy({
            Library.shared.isTag(playlist: $0)
        }) {
            // Tags, better reload if some tag changed while we edit this.
            let newTokens = TagEditor.desiredTagTokens(tracks: tracks)
            if Set(newTokens) != Set(tagTokens) {
                let prev = outlineTokens
                tagTokens = newTokens
                outlineView.animateDifference(childrenOf: masterItem, from: prev, to: outlineTokens)
            }
        }
    }
    
    func show(tracks: [Track]) {
        let prevTokens = outlineTokens
        tagTokens = TagEditor.desiredTagTokens(tracks: tracks)
        outlineView.animateDifference(childrenOf: masterItem, from: prevTokens, to: outlineTokens)
    }

    func delete(indices: IndexSet) {
        guard let items = indices.compactMap({ outlineView.item(atRow: $0) }) as? [ViewableTag] else {
            return // Can only delete tags
        }
        
        guard !items.contains(ViewableTag.new) else {
            return // Make sure all are deletable
        }
        
        // Can't use remove elements since enum.case !== enum.case (copy by value)
        outlineView.removeItems(at: IndexSet(items.map { tagTokens.index(of: $0)! }), inParent: masterItem, withAnimation: .slideDown)
        tagTokens = tagTokens.filter { !items.contains($0) }
        
        tokensChanged()
    }
}

extension TagEditor: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        // TODO With these unselectable we can't edit the cells
        return item is ViewableTag && (item as! ViewableTag) != .new
    }
}

extension TagEditor: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return (item as AnyObject) === masterItem ? outlineTokens.count : 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return outlineTokens[index]
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let viewableTag = item as? ViewableTag {
            switch viewableTag {
            case .tag(let playlist):
                if let view = outlineView.makeView(withIdentifier: CellIdentifiers.TokenCell, owner: nil) as? NSTableCellView, let tokenField = view.textField as? NSTokenField {
                    tokenField.delegate = nil // Kinda hacky tho, to make sure we get no change notification
                    tokenField.objectValue = [playlist]
                    tokenField.delegate = self
                    tokenField.isEditable = false
                    tokenField.isSelectable = false
                    
                    return view
                }
            case .new:
                if let view = outlineView.makeView(withIdentifier: CellIdentifiers.TokenCell, owner: nil) as? NSTableCellView, let tokenField = view.textField as? NSTokenField {
                    tokenField.delegate = self
                    tokenField.objectValue = []
                    tokenField.isEditable = true
                    tokenField.isSelectable = true
                    
                    return view
                }
            case .many(let playlists):
                if let view = outlineView.makeView(withIdentifier: CellIdentifiers.TokenCell, owner: nil) as? NSTableCellView, let tokenField = view.textField as? NSTokenField {
                    tokenField.delegate = self
                    tokenField.objectValue = [playlists]
                    tokenField.isEditable = false
                    tokenField.isSelectable = false
                    
                    return view
                }
            }
        }
        
        return nil
    }
}

extension TagEditor {
    fileprivate enum CellIdentifiers {
        static let TokenCell = NSUserInterfaceItemIdentifier(rawValue: "tokenCell")
    }

    enum ViewableTag : Hashable {
        case tag(playlist: PlaylistManual)
        case new
        case many(playlists: Set<PlaylistManual>)
        
        static func ==(lhs: ViewableTag, rhs: ViewableTag) -> Bool {
            switch (lhs, rhs) {
            case (.tag(let a), .tag(let b)):
                return a == b
            case (.new, .new):
                return true
            case (.many(let a), .many(let b)):
                return a == b
                
            default:
                return false
            }
        }
        
        var hashValue: Int {
            switch self {
            case .tag(let playlist):
                return playlist.hashValue
            case .new:
                return 1
            case .many(let playlists):
                return playlists.hashValue
            }
        }
    }
}
