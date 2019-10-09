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
    @objc dynamic var tracks: [Track] = []
    @IBOutlet var tracksController: NSArrayController!
        
    @IBOutlet var _titleBackground: NSImageView!
    @IBOutlet var _editorOutline: ActionOutlineView!
    
    let editActionStubs = ActionStubs()

    var data : [GroupData] = [
        GroupData(title: "Relations", icon: #imageLiteral(resourceName: "tag"), data: []),
        GroupData(title: "Musical", icon: #imageLiteral(resourceName: "music"), data: [
            EditData(title: "Genre", path: \Track.genre, options: nil),
            EditData(title: "BPM", path: \Track.bpmString, options: nil),
            EditData(title: "Initial Key", path: \Track.keyString, options: nil),
            ]),
        GroupData(title: "Metadata", icon: #imageLiteral(resourceName: "advanced-info"), data: [
            EditData(title: "Remix Author", path: \Track.remixAuthor, options: nil),
            EditData(title: "Comments", path: \Track.comments, options: nil),
            ]),
        GroupData(title: "Album", icon: #imageLiteral(resourceName: "album"), data: [
            EditData(title: "Album Author", path: \Track.albumArtist, options: nil),
            EditData(title: "Year", path: \Track.year, options: [.valueTransformerName: "IntStringNullable"]),
            EditData(title: "Publisher", path: \Track.publisher as PartialKeyPath<Track>, options: nil, skipWrite: true), // Live value
            EditData(title: "Track No.", path: \Track.trackNumber, options: [.valueTransformerName: "IntStringNullable"]),
            EditData(title: "CD No.", path: \Track.albumNumberOfCD, options: [.valueTransformerName: "IntStringNullable"], skipWrite: true), // Live Value
            EditData(title: "CD Count", path: \Track.albumNumberOfCDs, options: [.valueTransformerName: "IntStringNullable"], skipWrite: true), // Live Value
            ]),
        GroupData(title: "Info", icon: #imageLiteral(resourceName: "info"), data: [
            InfoData(title: "Duration") { $0.rDuration },
            EditData(title: "Loudness", path: \Track.loudness, options: [.valueTransformerName: "SimpleFloatString"], skipWrite: true),
            InfoData(title: "Kbps") { String(format: "%0.2f", $0.bitrate / 1024) },
            InfoData(title: "Location") { $0.path ?? "" },
            ]),
        ]
    
    var tagEditor: TagEditor!

    @IBAction func titleChanged(_ sender: Any) {
        attributeEdited(\Track.title)
    }
    
    @IBAction func authorChanged(_ sender: Any) {
        attributeEdited(\Track.author)
    }
    
    @IBAction func albumChanged(_ sender: Any) {
        attributeEdited(\Track.album)
    }
    
    override func awakeFromNib() {
        context = Library.shared.viewContext
        tagEditor = TagEditor(delegate: self)
        
        _editorOutline.target = self
        _editorOutline.enterAction = #selector(outlineViewAction(_:))
        _editorOutline.autosaveName = .init("trackEditor")
        _editorOutline.autosaveExpandedItems = true
        _editorOutline.setDraggingSourceOperationMask(.every, forLocal: false) // ESSENTIAL
        
        if AppDelegate.defaults.consume(toggle: "initialTrackEditorExpansion") {
            _editorOutline.expandItem(nil, expandChildren: true)
        }
    }

    func show(tracks: [Track]) {
        let converted = context.compactConvert(tracks)
        
        for track in converted {
            try! track.fetchMetadata()
        }
        
        self.tracks = converted

        tagEditor.show(tracks: tracks)
        
        for item in data.last!.data {
            _editorOutline.reloadItem(item, reloadChildren: false)
            // Use a for loop instead of the below since the below actually animates the change, removing all children and re-adding them
//            _editorOutline.reloadItem(data.last, reloadChildren: true) // Info, both computed rather than bound
        }
    }
    
    @IBAction func delete(_ sender: AnyObject) {
        tagEditor.delete(indices: _editorOutline.selectedRowIndexes)
    }
    
    func toggleEdit(textField: NSTextField) {
        guard textField.currentEditor() == nil else {
            textField.resignFirstResponder()
            return
        }
     
        guard textField.isEditable else {
            return
        }
        
        textField.becomeFirstResponder()
    }
    
    @IBAction func outlineViewAction(_ sender: Any) {
        let row = _editorOutline.clickedRow >= 0 ? _editorOutline.clickedRow : _editorOutline.selectedRow
        
        guard row >= 0, let view = _editorOutline.view(atColumn: 0, row: _editorOutline.clickedRow, makeIfNecessary: false) else {
            return
        }
        
        guard let cell = view as? TrackDataCell, let textField = cell.valueTextField else {
            // Some other text field
            if let cell = view as? NSTableCellView, let textField = cell.textField {
                guard textField.convert(textField.bounds, to: nil).contains(textField.window!.mouseLocationOutsideOfEventStream) else {
                    return
                }

                toggleEdit(textField: textField)
            }
            
            return
        }
        
        // tag text field
        guard view.convert(view.bounds, to: nil).contains(textField.window!.mouseLocationOutsideOfEventStream) else {
            return
        }

        toggleEdit(textField: textField)
    }
    
    @IBAction func outlineViewDoubleAction(_ sender: Any) {
        tagEditor.outlineViewDoubleAction(sender)
    }
    
    @IBAction func imageUpdated(_ sender: Any) {
        let image = (sender as! NSImageView).image
        
        for track in self.tracks {
            if AppDelegate.defaults[.editingTrackUpdatesAlbum], let album = track.rAlbum {
                album.artwork = image // Live Var
            }
        }
        
        try! self.context.save()
    }
    
    func attributeEdited(_ attribute: PartialKeyPath<Track>, skipWrite: Bool = false) {
        // After bound values have been updated
        // ...change location and save
        for track in self.tracks {
            // Don't call the collection method since it auto-saves in the wrong context
            Library.shared.mediaLocation.updateLocation(of: track)
            
            if AppDelegate.defaults[.editingTrackUpdatesAlbum], let album = track.rAlbum {
                switch attribute {
                case \Track.year:
                    album.year = track.year
                    try! album.writeMetadata(values: [\Track.year])
                case \Track.publisher:
                    album.publisher = track.publisher // Live Var
                case \Track.albumNumberOfCDs:
                    album.albumNumberOfCDs = track.albumNumberOfCDs // Live Var
                default:
                    break
                }
            }
        }
        
        try! self.context.save()
        
        if !skipWrite {
            for track in self.tracks {
                try! track.writeMetadata(values: [attribute])
            }
        }
    }
}

extension TrackEditor: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is GroupData
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return tagEditor.outlineView(outlineView, shouldSelectItem: item)
    }
    
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        return SubtleTableRowView()
    }
}

extension TrackEditor: NSOutlineViewDataSource {
    fileprivate enum CellIdentifiers {
        static let GroupTitleCell = NSUserInterfaceItemIdentifier(rawValue: "groupTitleCell")
        static let AttributeCell = NSUserInterfaceItemIdentifier(rawValue: "attributeCell")
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let group = item as? GroupData else {
            return data.count
        }
        
        guard !group.data.isEmpty else {
            // Tag hack
            return tagEditor.outlineView(outlineView, numberOfChildrenOfItem: item)
        }
        
        return group.data.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let group = item as? GroupData {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.GroupTitleCell, owner: nil) as? NSTableCellView {
                view.textField?.stringValue = group.title
                view.imageView?.image = group.icon
                
                return view
            }
        }
        else if let data = item as? EditData {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.AttributeCell, owner: nil) as? TrackDataCell {
                view.textField?.stringValue = data.title
                
                view.valueTextField?.bind(.value, to: tracksController!, withKeyPath: "selection." + data.path._kvcKeyPathString!, options: (data.options ?? [:]).merging([.nullPlaceholder: "..."], uniquingKeysWith: { (a, _) in a }))
                view.valueTextField?.bind(.toolTip, to: tracksController!, withKeyPath: "selection." + data.path._kvcKeyPathString!, options: data.options)
                view.valueTextField?.isEditable = true

                editActionStubs.bind(view.valueTextField!) { [unowned self] _ in
                    self.attributeEdited(data.path, skipWrite: data.skipWrite)
                }
                
                return view
            }
        }
        else if let data = item as? InfoData {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.AttributeCell, owner: nil) as? TrackDataCell {
                view.textField?.stringValue = data.title
                
                view.valueTextField?.stringValue = (tracks.uniqueElement ?=> data.show) ?? ""
                view.valueTextField?.toolTip = view.valueTextField?.stringValue
                view.valueTextField?.isEditable = false
                
                return view
            }
        }
        
        return tagEditor.outlineView(outlineView, viewFor: tableColumn, item: item)
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let group = item as? GroupData else {
            return data[index]
        }
        
        guard !group.data.isEmpty else {
            // Tag hack
            return tagEditor.outlineView(outlineView, child: index, ofItem: nil)
        }
        
        return group.data[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        return tagEditor.outlineView(outlineView, pasteboardWriterForItem: item)
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return item is GroupData ? 24.0 : 20.0
    }
    
    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        if let group = item as? GroupData {
            return group.title
        }
        
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        if let title = object as? String {
            return data.first { $0.title == title }
        }
        
        return nil
    }
}

extension TrackEditor: TagEditorDelegate {
    var tagEditorTracks: [Track] { return tracks }
    var tagEditorOutline: NSOutlineView { return _editorOutline }
    var tagEditorMasterItem: AnyObject { return data[0] }
    var tagEditorContext: NSManagedObjectContext { return context }
}

extension TrackEditor: NSOutlineViewContextSensitiveMenuDelegate {
    func currentMenu(forOutlineView outlineView: NSOutlineViewContextSensitiveMenu) -> NSMenu? {
        return tagEditor.currentMenu(forOutlineView: outlineView)
    }
}

class TrackDataCell: NSTableCellView {
    @IBOutlet var valueTextField: NSTextField?
}

extension TrackEditor {
    class GroupData {
        let title: String
        let icon: NSImage
        let data: [Any]
        
        init(title: String, icon: NSImage, data: [Any]) {
            self.title = title
            self.icon = icon
            self.data = data
        }
    }
    
    class EditData {
        let title: String
        let path: PartialKeyPath<Track>
        let options: [NSBindingOption: Any]?
        let skipWrite: Bool
        
        init(title: String, path: PartialKeyPath<Track>, options: [NSBindingOption: Any]?, skipWrite: Bool = false) {
            self.title = title
            self.path = path
            self.options = options
            self.skipWrite = skipWrite
        }
    }
    
    class InfoData {
        let title: String
        let show: (Track) -> String
        
        init(title: String, show: @escaping (Track) -> String) {
            self.title = title
            self.show = show
        }
    }    
}
