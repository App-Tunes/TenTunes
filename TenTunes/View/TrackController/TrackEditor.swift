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
    
    var delayedTracks: [Track]? = nil
    
    @IBOutlet var _contentView: NSView!
    @IBOutlet var _manyPlaceholder: NSView!
    @IBOutlet var _errorPlaceholder: NSView!
    @IBOutlet var _errorTextField: NSTextField!
    
    @IBOutlet var _editorOutline: ActionOutlineView!
    
    let editActionStubs = ActionStubs()
    
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
        
        init(title: String, path: PartialKeyPath<Track>, options: [NSBindingOption: Any]?) {
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
    
    enum ViewableTag : Equatable {
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
    }

    var data : [GroupData] = [
        GroupData(title: "Tags", icon: #imageLiteral(resourceName: "tag"), data: []),
        GroupData(title: "Musical", icon: #imageLiteral(resourceName: "music"), data: [
            EditData(title: "Genre", path: \Track.genre, options: nil),
            EditData(title: "BPM", path: \Track.bpmString, options: nil),
            EditData(title: "Initial Key", path: \Track.keyString, options: nil),
            ]),
        GroupData(title: "Album", icon: #imageLiteral(resourceName: "album"), data: [
            EditData(title: "Album Author", path: \Track.albumArtist, options: nil),
            EditData(title: "Remix Author", path: \Track.remixAuthor, options: nil),
            EditData(title: "Year", path: \Track.year, options: [.valueTransformerName: "IntStringNullable"]),
            EditData(title: "Track No.", path: \Track.trackNumber, options: [.valueTransformerName: "IntStringNullable"]),
            EditData(title: "Comments", path: \Track.comments, options: nil),
            ]),
        GroupData(title: "Info", icon: #imageLiteral(resourceName: "info"), data: [
            InfoData(title: "Duration") { $0.rDuration },
            InfoData(title: "Kbps") { String(format: "%0.2f", $0.bitrate / 1024) },
            InfoData(title: "Location") { $0.path ?? "" },
            ]),
        ]

    var tagTokens : [ViewableTag] = []
    var outlineTokens : [ViewableTag] { return tagTokens + [.new] }

    @IBAction func titleChanged(_ sender: Any) {
        try! self.context.save()
        
        for track in self.tracks {
            try! track.writeMetadata(values: [\Track.title])
        }
    }
    
    @IBAction func authorChanged(_ sender: Any) {
        try! self.context.save()
        
        for track in self.tracks {
            try! track.writeMetadata(values: [\Track.author])
        }
    }
    
    @IBAction func albumChanged(_ sender: Any) {
        try! self.context.save()
        
        for track in self.tracks {
            try! track.writeMetadata(values: [\Track.album])
        }
    }
    
    override func viewDidLoad() {
        showError(text: "No Tracks Selected")
        _editorOutline.expandItem(nil, expandChildren: true)
        
        _editorOutline.target = self
        _editorOutline.enterAction = #selector(outlineViewAction(_:))
        
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: Library.shared.viewContext)
    }
    
    @IBAction func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        
        if updates.of(type: Playlist.self).anyMatch({
            Library.shared.isTag(playlist: $0)
        }) {
            // Tags, better reload if some tag changed while we edit this.
            let prev = outlineTokens
            calculateTagTokens()
            _editorOutline.animateDifference(childrenOf: data[0], from: prev, to: outlineTokens)
        }
    }

    override func viewWillAppear() {
        // Kinda Hacky but eh
        if _errorTextField.stringValue == "View Hidden", let delayedTracks = delayedTracks {
            present(tracks: delayedTracks) // Try again
        }
    }
        
    func present(tracks: [Track]) {
        guard !view.isHidden else {
            delayedTracks = tracks
            showError(text: "View Hidden")
            return
        }
        delayedTracks = nil
        
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
        let converted = context.compactConvert(tracks)
        
        for track in converted {
            try! track.fetchMetadata()
        }
        
        self.tracks = converted

        let prevTokens = outlineTokens
        calculateTagTokens()
        _editorOutline.animateDifference(childrenOf: data[0], from: prevTokens, to: outlineTokens)
        
        _editorOutline.reloadItem(data.last, reloadChildren: true) // Info, both computed rather than bound

        view.setFullSizeContent(_contentView)
    }
    
    func calculateTagTokens() {
        let (omittedTags, sharedTags) = findShares(in: tracks.map { $0.tags })
        let omittedPart : [ViewableTag] = omittedTags.isEmpty ? [] : [.many(playlists: omittedTags)]
        tagTokens = omittedPart + sharedTags.sorted { $0.name < $1.name }.map { .tag(playlist: $0) }
    }
    
    func showError(text: String) {
        tracks = []
        
        _errorTextField.stringValue = text
        view.setFullSizeContent(_errorPlaceholder)
    }
    
    func suggest(tracks: [Track]) {
        self.tracks = []
        delayedTracks = tracks
        
        view.setFullSizeContent(_manyPlaceholder)
    }
    
    @IBAction func showSuggestedTracks(_ sender: Any) {
        delayedTracks ?=> show
        delayedTracks = nil
    }
    
    @IBAction func delete(_ sender: AnyObject) {
        guard let items = _editorOutline.selectedRowIndexes.compactMap({ _editorOutline.item(atRow: $0) }) as? [ViewableTag] else {
            return // Can only delete tags
        }
        
        guard !items.contains(ViewableTag.new) else {
            return // Make sure all are deletable
        }
        
        // Can't use remove elements since enum.case !== enum.case (copy by value)
        _editorOutline.removeItems(at: IndexSet(items.map { tagTokens.index(of: $0)! }), inParent: data[0], withAnimation: .slideDown)
        tagTokens = tagTokens.filter { !items.contains($0) }

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
    
    @IBAction func imageUpdated(_ sender: Any) {
        try! self.context.save()
        
        for track in self.tracks {
            try! track.writeMetadata(values: [\Track.artwork])
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
            return outlineTokens.count
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
                
                editActionStubs.bind(view.valueTextField!) { _ in
                    // After bound values have been updated
                    // ...change location and save
                    for track in self.tracks {
                        // Don't call the collection method since it auto-saves in the wrong context
                        Library.shared.mediaLocation.updateLocation(of: track)
                    }
                    
                    try! self.context.save()
                    
                    for track in self.tracks {
                        try! track.writeMetadata(values: [data.path])
                    }
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
        else if let viewableTag = item as? ViewableTag {
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
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let group = item as? GroupData else {
            return data[index]
        }
        
        guard !group.data.isEmpty else {
            // Tag hack
            return outlineTokens[index]
        }
        
        return group.data[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item is GroupData
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        // TODO With these unselectable we can't edit the cells
        return item is ViewableTag && (item as! ViewableTag) != .new
    }
}

extension TrackEditor: NSOutlineViewDataSource {
    
}

class TrackDataCell: NSTableCellView {
    @IBOutlet var valueTextField: NSTextField?
}

