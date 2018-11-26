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
            EditData(title: "Track No.", path: \Track.trackNumber, options: [.valueTransformerName: "IntStringNullable"]),
            EditData(title: "CD No.", path: \Track.albumNumberOfCD, options: [.valueTransformerName: "IntStringNullable"]),
            EditData(title: "CD Count", path: \Track.albumNumberOfCDs, options: [.valueTransformerName: "IntStringNullable"]),
            ]),
        GroupData(title: "Info", icon: #imageLiteral(resourceName: "info"), data: [
            InfoData(title: "Duration") { $0.rDuration },
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
    
    override func viewDidLoad() {
        tagEditor = TagEditor(delegate: self)
        
        _editorOutline.target = self
        _editorOutline.enterAction = #selector(outlineViewAction(_:))
        _editorOutline.autosaveName = .init("trackEditor")
        _editorOutline.autosaveExpandedItems = true

        if UserDefaults.standard.consume(toggle: "initialTrackEditorExpansion") {
            _editorOutline.expandItem(nil, expandChildren: true)
        }
        
        _titleBackground.wantsLayer = true
        _titleBackground.alphaValue = 0.3
        
        tagEditor.viewDidLoad()
    }

    func show(tracks: [Track]) {
//        context = Library.shared.newConcurrentContext()
//        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy // User is always right
        context = Library.shared.viewContext
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
        guard textField.convert(textField.bounds, to: nil).contains(textField.window!.mouseLocationOutsideOfEventStream) else {
            return
        }
        
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
        
        if let cell = view as? TrackDataCell, let textField = cell.valueTextField {
            toggleEdit(textField: textField)
        }
        else if let cell = view as? NSTableCellView, let textField = cell.textField {
            toggleEdit(textField: textField)
        }
    }
    
    @IBAction func outlineViewDoubleAction(_ sender: Any) {
        tagEditor.outlineViewDoubleAction(sender)
    }
    
    @IBAction func imageUpdated(_ sender: Any) {
        let image = (sender as! NSImageView).image
        
        for track in self.tracks {
            if UserDefaults.standard.editingTrackUpdatesAlbum == .update, let album = track.rAlbum {
                album.artwork = image // Dynamic Var, is written automagically
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
        static let NameCell = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
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
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? TrackDataCell {
                view.textField?.stringValue = data.title
                
                view.valueTextField?.bind(.value, to: tracksController, withKeyPath: "selection." + data.path._kvcKeyPathString!, options: (data.options ?? [:]).merging([.nullPlaceholder: "..."], uniquingKeysWith: { (a, _) in a }))
                
                editActionStubs.bind(view.valueTextField!) { [unowned self] _ in
                    self.attributeEdited(data.path, skipWrite: data.skipWrite)
                }
                
                return view
            }
        }
        else if let data = item as? InfoData {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.NameCell, owner: nil) as? TrackDataCell {
                view.textField?.stringValue = data.title
                
                view.valueTextField?.stringValue = (tracks.uniqueElement ?=> data.show) ?? ""
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
