//
//  SmartPlaylistRulesController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 18.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc protocol SmartPlaylistRulesControllerDelegate {
    @objc optional func smartPlaylistRulesController(_ controller: SmartPlaylistRulesController, changedRules rules: SmartPlaylistRules)
    
    @objc optional func editingEnded(smartPlaylistRulesController: SmartPlaylistRulesController, notification: Notification)

    @objc optional func smartPlaylistRulesController(confirmedSearch: SmartPlaylistRulesController)
}

class SmartPlaylistRulesController : NSViewController, TTTokenFieldDelegate {
    static let pasteboardTypeTokens = NSPasteboard.PasteboardType("TenTunes_SmartPlaylistTokens")

    @IBOutlet @objc weak open var delegate: SmartPlaylistRulesControllerDelegate?
    
    @IBOutlet var _tokenField: TTTokenField!
    
    @IBOutlet var _tokenMenu: NSMenu!
    @IBOutlet var _addTokenButton: SMButtonWithMenu!
    
    @IBOutlet var _accumulationType: NSPopUpButton!
    
    var lastEditingString: String = ""
    
    override func awakeFromNib() {
        PopupEnum.represent(in: _accumulationType, with: [SmartPlaylistRules.Mode.all, SmartPlaylistRules.Mode.any], title: { $0.title })
        
        _tokenField.tokenizingCharacterSet = CharacterSet(charactersIn: "%%")
    }
    
    var rules: SmartPlaylistRules {
        get {
            let mode = _accumulationType.selectedItem?.representedObject as! SmartPlaylistRules.Mode
            return SmartPlaylistRules(tokens: tokens, mode: mode)
        }
        set {
            _accumulationType.select(_accumulationType.menu!.item(withRepresentedObject: newValue.mode))
            tokens = newValue.tokens
        }
    }

    var tokens: [SmartPlaylistRules.Token] {
        get { return SmartPlaylistRulesController.tokenize(_tokenField.objectValue) }
        set { _tokenField.objectValue = SmartPlaylistRulesController.untokenize(newValue) as NSArray }
    }
    
    var playlists: [Playlist] {
        return Library.shared.allPlaylists().filter {
            $0.path.contains(Library.shared.tagPlaylist)
        }
    }
    
    static func tokenize(_ object: Any?) -> [SmartPlaylistRules.Token] {
        return (object as? NSArray)?.compactMap {
            if let string = $0 as? String {
                return string.isEmpty ? nil : SmartPlaylistRules.Token.Search(string: string)
            }
            return ($0 as! SmartPlaylistRules.Token)
            } ?? []
    }
    
    static func untokenize(_ object: [SmartPlaylistRules.Token]) -> [Any] {
        return (object.map {
            if let search = $0 as? SmartPlaylistRules.Token.Search {
                return search.string
            }
            return $0
        } as [Any])
    }
    
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [TTTokenField.TokenGroup]? {
        var groups: [TTTokenField.TokenGroup] = []
        
        if let int = Int(substring), int > 0 {
            groups.append(.init(title: "File Quality", contents: [
                SmartPlaylistRules.Token.MinBitrate(bitrate: int, above: true),
                SmartPlaylistRules.Token.MinBitrate(bitrate: int, above: false)
                ]))
        }
        
        if let date = HumanDates.date(from: substring) {
            groups.append(.init(title: "Release Date", contents: [
                SmartPlaylistRules.Token.ReleasedAfter(date: date, after: true),
                SmartPlaylistRules.Token.ReleasedAfter(date: date, after: false)
                ]))

            groups.append(.init(title: "Add Date", contents: [
                SmartPlaylistRules.Token.AddedAfter(date: date, after: true),
                SmartPlaylistRules.Token.AddedAfter(date: date, after: false)
                ]))
        }
        
        groups.append(.init(title: "Has Tag", contents: playlistResults(search: substring, tag: true)))
        groups.append(.init(title: "Contained In Playlist", contents: playlistResults(search: substring, tag: false)))
        groups.append(.init(title: "Created By", contents: authorResults(search: substring)))
        groups.append(.init(title: "Released on Album", contents: albumResults(search: substring)))
        groups.append(.init(title: "Genre", contents: genreResults(search: substring)))
        
        return groups
    }
    
    static func sorted<L : SmartPlaylistRules.Token>(tokens: [L]) -> [L] {
        return tokens.sorted { (a, b) -> Bool in
            a.representation(in: Library.shared.viewContext).count < b.representation(in: Library.shared.viewContext).count
        }
    }
    
    func genreResults(search: String) -> [SmartPlaylistRules.Token.Genre] {
        let found = Library.shared.allGenres.filter({ $0.range(of: search, options: [.caseInsensitive, .diacriticInsensitive]) != nil })
        
        return SmartPlaylistRulesController.sorted(tokens: found.map { SmartPlaylistRules.Token.Genre(genre: $0) })
    }
    
    func albumResults(search: String) -> [SmartPlaylistRules.Token.InAlbum] {
        let found = Library.shared.allAlbums.filter({ $0.title.range(of: search, options: [.caseInsensitive, .diacriticInsensitive]) != nil })
        
        return SmartPlaylistRulesController.sorted(tokens: found.map { SmartPlaylistRules.Token.InAlbum(album: $0) })
    }
    
    func authorResults(search: String) -> [SmartPlaylistRules.Token.Author] {
        let found = Library.shared.allAuthors.filter({ $0.description.range(of: search, options: [.caseInsensitive, .diacriticInsensitive]) != nil })
        
        return SmartPlaylistRulesController.sorted(tokens: found.map { SmartPlaylistRules.Token.Author(author: $0) })
    }
    
    func playlistResults(search: String, tag: Bool) -> [SmartPlaylistRules.Token.InPlaylist] {
        let found = (tag ? Library.shared.allTags() : playlists).filter({ $0.name.range(of: search, options: [.caseInsensitive, .diacriticInsensitive]) != nil })
        
        return SmartPlaylistRulesController.sorted(tokens: found.map({ SmartPlaylistRules.Token.InPlaylist(playlist: $0, isTag: tag) }))
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        guard let token = (representedObject as? SmartPlaylistRules.Token) else {
            return nil
        }
        
        return token.icons + " " + token.representation(in: Library.shared.viewContext)
    }
    
    func tokenField(_ tokenField: NSTokenField, changedTokens tokens: [Any]) {
        if lastEditingString != (tokens.last as? SmartPlaylistRules.Token.Search)?.string {
            delegate?.smartPlaylistRulesController?(self, changedRules: rules)
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        return !(representedObject is SmartPlaylistRules.Token.Search)
    }
    
    func tokenField(_ tokenField: NSTokenField, menuForRepresentedObject representedObject: Any) -> NSMenu? {
        for item in _tokenMenu.items { item.representedObject = representedObject }
        return _tokenMenu
    }
    
    @IBAction func invertToken(_ sender: Any) {
        let token = (sender as! NSMenuItem).representedObject as! SmartPlaylistRules.Token

        _tokenField.replace(tokenAt: tokens.index(of: token), with: token.inverted())
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        if _tokenField.editingString != lastEditingString && lastEditingString != (rules.tokens.last as? SmartPlaylistRules.Token.Search)?.string {
            // Live search changed
            lastEditingString = _tokenField.editingString
            delegate?.smartPlaylistRulesController?(self, changedRules: rules)
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        delegate?.editingEnded?(smartPlaylistRulesController: self, notification: obj)
        _tokenField.autocompletePopover.close()
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        let labelField = control as! TTTokenField
        
        if commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
            // Use the first matching tag
            if let tag = playlistResults(search: labelField.editingString, tag: true).first {
                let actualTag = NSEvent.modifierFlags.contains(.shift) ? tag.inverted() : tag
                labelField.autocomplete(with: actualTag)
                return true
            }
        }
        else if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            labelField.autocompletePopover.close()
            delegate?.smartPlaylistRulesController?(confirmedSearch: self)
            return true
        }
        
        return false
    }
    
    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenField.TokenStyle {
        return representedObject is String ? .none : .default
    }
    
    @IBAction func accumulationChanged(_ sender: Any) {
        delegate?.smartPlaylistRulesController?(self, changedRules: rules)
    }
    
    @IBAction func showAddTokenMenu(_ sender: Any) {
        _addTokenButton.showContextMenu()
    }
    
    @IBAction func addTokenLinkedFile(_ sender: Any) {
        _tokenField.items.append(SmartPlaylistRules.Token.InMediaDirectory(false))
    }

    @IBAction func addTokenMissingFile(_ sender: Any) {
        _tokenField.items.append(SmartPlaylistRules.Token.FileMissing(true))
    }

    @IBAction func addTokenLowQuality(_ sender: Any) {
        _tokenField.items.append(SmartPlaylistRules.Token.MinBitrate(bitrate: 240, above: false))
    }

    @IBAction func addTokenRecentlyAdded(_ sender: Any) {
        guard let date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else {
            NSAlert.warning(title: "Date Problems", text: "We could not find last week! Weird.")
            return
        }
        
        _tokenField.items.append(SmartPlaylistRules.Token.AddedAfter(date: date, after: true))
    }
}

extension SmartPlaylistRulesController {
    func tokenField(_ tokenField: NSTokenField, writeRepresentedObjects objects: [Any], to pboard: NSPasteboard) -> Bool {
        pboard.declareTypes([SmartPlaylistRulesController.pasteboardTypeTokens], owner: self)
        pboard.setData(NSKeyedArchiver.archivedData(withRootObject: SmartPlaylistRulesController.tokenize(objects)),
                       forType: SmartPlaylistRulesController.pasteboardTypeTokens)
        
        return true
    }
    
    func tokenField(_ tokenField: NSTokenField, readFrom pboard: NSPasteboard) -> [Any]? {
        guard let data = pboard.data(forType: SmartPlaylistRulesController.pasteboardTypeTokens),
            let tokens = NSKeyedUnarchiver.unarchiveObject(with: data) as? [SmartPlaylistRules.Token] else {
            return nil
        }
        
        return SmartPlaylistRulesController.untokenize(tokens)
    }
}
