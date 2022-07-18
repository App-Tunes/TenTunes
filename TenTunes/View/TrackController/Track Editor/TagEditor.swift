//
//  TagEditor.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import TunesUI

protocol TagEditorDelegate : AnyObject {
    var tagEditorTracks: [Track] { get }
    var tagEditorOutline: NSOutlineView { get }
    var tagEditorMasterItem: AnyObject { get }
    var tagEditorContext: NSManagedObjectContext { get }
}

class TagEditor: NSObject {
    weak var delegate: TagEditorDelegate?
    
    init(delegate: TagEditorDelegate) {
        self.delegate = delegate
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: context)
    }
    
    var tagTokens : [ViewableTag] = []
    var outlineTokens : [ViewableTag] { return tagTokens + [.new] }
    
    var tracks: [Track] { return delegate!.tagEditorTracks }
    var outlineView: NSOutlineView { return delegate!.tagEditorOutline }
    var masterItem: AnyObject { return delegate!.tagEditorMasterItem }
    var context: NSManagedObjectContext { return delegate!.tagEditorContext }

    var trackActions: TrackActions?
    var playlistActions: PlaylistActions?
    
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
				
				ListTransition.findBest(before: prev, after: outlineTokens)
					.executeAnimationsInOutlineView(outlineView, childrenOf: masterItem)
            }
        }
    }
    
    func show(tracks: [Track]) {
        let prevTokens = outlineTokens
        tagTokens = TagEditor.desiredTagTokens(tracks: tracks)
		
		ListTransition.findBest(before: prevTokens, after: outlineTokens)
			.executeAnimationsInOutlineView(outlineView, childrenOf: masterItem)
    }

    func delete(indices: IndexSet) {
        guard let items = indices.compactMap({ outlineView.item(atRow: $0) }) as? [ViewableTag] else {
            return // Can only delete tags
        }
        
        guard !items.contains(ViewableTag.new) else {
            return // Make sure all are deletable
        }
        
        // Can't use remove elements since enum.case !== enum.case (copy by value)
        outlineView.removeItems(at: IndexSet(items.map { tagTokens.firstIndex(of: $0)! }), inParent: masterItem, withAnimation: .slideDown)
        tagTokens = tagTokens.filter { !items.contains($0) }
        
        tokensChanged()
    }
    
    @IBAction func outlineViewDoubleAction(_ sender: Any) {
        guard let viewableTag = outlineView.item(atRow: outlineView.clickedRow) as? ViewableTag else {
            return
        }
        
        switch viewableTag {
        case .tag(let playlist):
            // TODO Too omniscient
            ViewController.shared.playlistController.select(playlist: playlist)
        default:
            break
        }
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
        guard let viewableTag = item as? ViewableTag else {
            return nil
        }
        
        switch viewableTag {
        case .related(let track):
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.relatedTrackCell, owner: nil) as? NSTableCellView {
                view.imageView?.wantsLayer = true
                view.imageView?.layer!.borderWidth = 1.0
                view.imageView?.layer!.borderColor = NSColor.lightGray.cgColor.copy(alpha: CGFloat(0.333))
                view.imageView?.layer!.cornerRadius = 3.0
                view.imageView?.layer!.masksToBounds = true
                
                view.imageView?.bind(.value, to: track, withKeyPath: \.artworkPreview, options: [.nullPlaceholder: Album.missingArtwork])
                
                view.textField?.bind(.value, to: track, withKeyPath: \.rTitle)
                view.textField?.bind(.toolTip, to: track, withKeyPath: \.rTitle)

                return view
            }
        case .tag(let playlist):
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.tagCell, owner: nil) as? NSTableCellView {
                view.textField?.bind(.value, to: playlist, withKeyPath: \.name)
                view.textField?.bind(.toolTip, to: playlist, withKeyPath: \.name)

                return view
            }
        case .new:
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.newRelationCell, owner: nil) as? NSTableCellView, let tokenField = view.textField as? NSTokenField {
                tokenField.delegate = self
                tokenField.objectValue = []
                tokenField.isEditable = true
                tokenField.isSelectable = true

                return view
            }
        case .many(let items):
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.newRelationCell, owner: nil) as? NSTableCellView, let tokenField = view.textField as? NSTokenField {
                tokenField.delegate = self
                tokenField.objectValue = [items]
                tokenField.isEditable = false
                tokenField.isSelectable = false
                
                return view
            }
        }
        
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        switch item {
        case ViewableTag.related(let track):
            return Library.shared.export().pasteboardItem(representing: track)
        case ViewableTag.tag(let playlist):
            return Library.shared.export().pasteboardItem(representing: playlist)
        default:
            return nil
        }
    }
}

extension TagEditor: NSOutlineViewContextSensitiveMenuDelegate {
    func currentMenu(forOutlineView outlineView: NSOutlineViewContextSensitiveMenu) -> NSMenu? {
        guard let items = outlineView.contextualClickedRows.compactMap(outlineView.item) as? [ViewableTag] else {
            return nil
        }
        
        if let tracks = items.caseAs(ViewableTag.related) {
            trackActions = TrackActions.create(.none(tracks: tracks))
            return trackActions?._menu
        }
        else if let playlists = items.caseAs(ViewableTag.tag) {
            playlistActions = PlaylistActions.create(.invisible(playlists: playlists))
            return playlistActions?.menu()
        }

        return nil
    }
}

extension TagEditor {
    fileprivate enum CellIdentifiers {
        static let relatedTrackCell = NSUserInterfaceItemIdentifier(rawValue: "relatedTrackCell")
        static let tagCell = NSUserInterfaceItemIdentifier(rawValue: "tagCell")
        static let newRelationCell = NSUserInterfaceItemIdentifier(rawValue: "newRelationCell")
    }

    enum ViewableTag : Hashable {
        case related(track: Track)
        case tag(playlist: PlaylistManual)
        case new
        case many(items: Set<NSManagedObject>)
        
        static func ==(lhs: ViewableTag, rhs: ViewableTag) -> Bool {
            switch (lhs, rhs) {
            case (.related(let a), .related(let b)):
                return a == b
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
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .related(let track):
                hasher.combine(track)
            case .tag(let playlist):
                hasher.combine(playlist)
            case .new:
                break
            case .many(let playlists):
                hasher.combine(playlists)
            }
        }
    }
}
