//
//  FileTagEditor.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 10.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class TrackEditor: NSViewController {
    static let addPlaceholder = PlaylistEmpty()
    
    var context: NSManagedObjectContext!
    @objc dynamic var tracks: [Track] = []
    @IBOutlet var tracksController: NSArrayController!
    
    var manyTracks: [Track] = []
    
    @IBOutlet var _contentView: NSView!
    @IBOutlet var _manyPlaceholder: NSView!
    @IBOutlet var _errorPlaceholder: NSView!
    @IBOutlet var _errorTextField: NSTextField!
    
    @IBOutlet var _editorOutline: ActionOutlineView!
    
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
        let path: String
        let options: [NSBindingOption: Any]?
        
        init(title: String, path: String, options: [NSBindingOption: Any]?) {
            self.title = title
            self.path = path
            self.options = options
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

    var data : [GroupData] = [
        GroupData(title: "Tags", icon: #imageLiteral(resourceName: "tag"), data: []),
        GroupData(title: "Musical", icon: #imageLiteral(resourceName: "music"), data: [
            EditData(title: "Genre", path: "genre", options: nil),
            EditData(title: "BPM", path: "bpmString", options: nil),
            EditData(title: "Initial Key", path: "keyString", options: nil),
            ]),
        GroupData(title: "Album", icon: #imageLiteral(resourceName: "album"), data: [
            EditData(title: "Album Author", path: "albumArtist", options: nil),
            EditData(title: "Remix Author", path: "remixAuthor", options: nil),
            EditData(title: "Year", path: "year", options: [.valueTransformerName: "IntStringNullable"]),
            EditData(title: "Track No.", path: "trackNumber", options: [.valueTransformerName: "IntStringNullable"]),
            ]),
        GroupData(title: "Info", icon: #imageLiteral(resourceName: "info"), data: [
            InfoData(title: "Duration") { $0.rDuration },
            InfoData(title: "Kbps") { String(format: "%0.2f", $0.bitrate / 1024) },
            InfoData(title: "Location") { $0.path ?? "" },
            ]),
        ]

    var tagTokens : [Any] = []

    override func viewDidLoad() {
        showError(text: "No Tracks Selected")
        _editorOutline.expandItem(nil, expandChildren: true)
        
        _editorOutline.target = self
        _editorOutline.enterAction = #selector(outlineViewAction(_:))
    }
        
    func present(tracks: [Track]) {
        if tracks.count == 0 {
            showError(text: "No Tracks Selected")
        }
        else if tracks.contains(where: { $0.url == nil }) {
            // TODO Show what we know but don't make it editable
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
//        context = Library.shared.newConcurrentContext()
//        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy // User is always right
        context = Library.shared.viewContext
        self.tracks = context.compactConvert(tracks)
        
        for track in self.tracks {
            try! track.fetchMetadata()
        }
        
        let (omittedTags, sharedTags) = findShares(in: tracks.map { $0.tags })
        let omittedPart = omittedTags.isEmpty ? [] : [omittedTags]
        tagTokens = omittedPart as [Any] + sharedTags.sorted { $0.name < $1.name } as [Any] + [TrackEditor.addPlaceholder]

        _editorOutline.reloadItem(data[0], reloadChildren: true) // Tags
        _editorOutline.reloadItem(data.last, reloadChildren: true) // Info, both computed rather than bound

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
    
    @IBAction func trackChanged(_ sender: Any) {
        for track in tracks {
            // Don't call the collection method since it auto-saves in the wrong context
            Library.shared.mediaLocation.updateLocation(of: track)
        }
        
        try! context.save()

        for track in tracks {
            track.writeMetadata()
        }
    }
    
    @IBAction func showSuggestedTracks(_ sender: Any) {
        show(tracks: manyTracks)
    }
    
    @IBAction func delete(_ sender: AnyObject) {
        let items = _editorOutline.selectedRowIndexes.compactMap({ _editorOutline.item(atRow: $0) })
        
        guard items.allMatch({ $0 is Playlist || $0 is Set<Playlist>}) else {
            // Make sure it's deletable
            return
        }
        
        _editorOutline.animateDelete(elements: items)
        tagTokens = tagTokens.filter { label in !items.contains { (label as AnyObject) === ($0 as AnyObject) }}

        tokensChanged()
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
}

extension TrackEditor: NSOutlineViewDelegate {
    fileprivate enum CellIdentifiers {
        static let GroupTitleCell = NSUserInterfaceItemIdentifier(rawValue: "groupTitleCell")
        static let NameCell = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
        static let TokenCell = NSUserInterfaceItemIdentifier(rawValue: "tokenCell")
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let group = item as? GroupData else {
            return data.count
        }
        
        guard !group.data.isEmpty else {
            // Tag hack
            return tagTokens.count
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
                
                view.valueTextField?.bind(.value, to: tracksController, withKeyPath: "selection." + data.path, options: (data.options ?? [:]).merging([.nullPlaceholder: "..."], uniquingKeysWith: { (a, _) in a }))
                view.valueTextField?.action = #selector(trackChanged(_:))
                view.valueTextField?.target = self
                
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
        else if let multiple = item as? Set<Playlist> {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.TokenCell, owner: nil) as? NSTableCellView, let tokenField = view.textField as? NSTokenField {
                tokenField.delegate = self
                tokenField.objectValue = [multiple]
                
                return view
            }
        }
        else if let tag = item as? PlaylistProtocol {
            if let view = outlineView.makeView(withIdentifier: CellIdentifiers.TokenCell, owner: nil) as? NSTableCellView, let tokenField = view.textField as? NSTokenField {
                tokenField.delegate = nil // Kinda hacky tho, to make sure we get no change notification
                tokenField.objectValue = (tag is Playlist ? [tag] : [])
                tokenField.delegate = self
                tokenField.isEditable = tag is PlaylistEmpty
                
                return view
            }
        }
        
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let group = item as? GroupData else {
            return data[index]
        }
        
        guard !group.data.isEmpty else {
            // Tag hack
            return tagTokens[index]
        }
        
        return group.data[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is GroupData
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        // TODO With these unselectable we can't edit the cells
        return item is Set<Playlist> || item is Playlist
    }
}

extension TrackEditor: NSOutlineViewDataSource {
    
}

class TrackDataCell: NSTableCellView {
    @IBOutlet var valueTextField: NSTextField?
}

