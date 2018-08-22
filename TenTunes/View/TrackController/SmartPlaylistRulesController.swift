//
//  LabelDelegate.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 18.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc protocol SmartPlaylistRulesControllerDelegate {
    @objc optional func smartPlaylistRulesController(_ controller: SmartPlaylistRulesController, changedRules rules: SmartPlaylistRules)
    
    @objc optional func editingEnded(smartPlaylistRulesController: SmartPlaylistRulesController, notification: Notification)
}

class SmartPlaylistRulesController : NSViewController, TTTokenFieldDelegate {
    @IBOutlet @objc weak open var delegate: SmartPlaylistRulesControllerDelegate?
    
    @IBOutlet var _tokenField: TTTokenField!
    
    @IBOutlet var _tokenMenu: NSMenu!
    
    @IBOutlet var _accumulationType: NSPopUpButton!

    enum Accumulation {
        case all, any
        
        var title: String {
            switch self {
            case .all:
                return "All"
            case .any:
                return "Any"
            }
        }
    }
    
    override func awakeFromNib() {
        PopupEnum.represent(in: _accumulationType, with: [Accumulation.all, Accumulation.any], title: { $0.title })
    }
    
    var rules: SmartPlaylistRules {
        get {
            let acc = _accumulationType.selectedItem?.representedObject as! Accumulation
            return SmartPlaylistRules(tokens: tokens, any: acc == .any)
        }
        set {
            _accumulationType.select(_accumulationType.menu!.item(withRepresentedObject: newValue.any ? Accumulation.any : Accumulation.all))
            tokens = newValue.tokens
        }
    }
    
    var tokens: [SmartPlaylistRules.Token] {
        get { return _tokenField.tokens as! [SmartPlaylistRules.Token] }
        set { _tokenField.tokens = newValue }
    }
    
    var playlists: [Playlist] {
        return Library.shared.allPlaylists().filter {
            !Library.shared.path(of: $0).contains(Library.shared.tagPlaylist)
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [TTTokenField.TokenGroup]? {
        let compareSubstring = substring.lowercased()
        
        var groups: [TTTokenField.TokenGroup] = [
            .init(title: "Search For", contents: [SmartPlaylistRules.Token.Search(string: substring)]),
            ]
        
        if let int = Int(substring), int > 0 {
            groups.append(.init(title: "Kbps", contents: [
                SmartPlaylistRules.Token.MinBitrate(bitrate: int, above: true),
                SmartPlaylistRules.Token.MinBitrate(bitrate: int, above: false)
                ]))
        }
        
        groups.append(.init(title: "Has Tag", contents: playlistResults(search: compareSubstring, tag: true)))
        groups.append(.init(title: "Contained In Playlist", contents: playlistResults(search: compareSubstring, tag: false)))
        groups.append(.init(title: "Created By", contents: authorResults(search: compareSubstring)))
        groups.append(.init(title: "Released on Album", contents: albumResults(search: compareSubstring)))
        groups.append(.init(title: "Genre", contents: genreResults(search: compareSubstring)))
        
        return groups
    }
    
    static func sorted<L : SmartPlaylistRules.Token>(tokens: [L]) -> [L] {
        return tokens.sorted { (a, b) -> Bool in
            a.representation(in: Library.shared.viewContext).count < b.representation(in: Library.shared.viewContext).count
        }
    }
    
    func genreResults(search: String) -> [SmartPlaylistRules.Token.Genre] {
        let found = search.count > 0 ? Library.shared.allGenres.filter({ $0.lowercased().range(of: search) != nil }) : Library.shared.allGenres
        return SmartPlaylistRulesController.sorted(tokens: found.map { SmartPlaylistRules.Token.Genre(genre: $0) })
    }
    
    func albumResults(search: String) -> [SmartPlaylistRules.Token.InAlbum] {
        let found = search.count > 0 ? Library.shared.allAlbums.filter({ $0.title.lowercased().range(of: search) != nil }) : Library.shared.allAlbums
        return SmartPlaylistRulesController.sorted(tokens: found.map { SmartPlaylistRules.Token.InAlbum(album: $0) })
    }
    
    func authorResults(search: String) -> [SmartPlaylistRules.Token.Author] {
        let found = search.count > 0 ? Library.shared.allAuthors.filter({ $0.lowercased().range(of: search) != nil }) : Library.shared.allAuthors
        return SmartPlaylistRulesController.sorted(tokens: found.map { SmartPlaylistRules.Token.Author(author: $0) })
    }
    
    func playlistResults(search: String, tag: Bool) -> [SmartPlaylistRules.Token.InPlaylist] {
        let found = search.count > 0 ? (tag ? Library.shared.allTags() : playlists).filter({ $0.name.lowercased().range(of: search) != nil }) : playlists
        return SmartPlaylistRulesController.sorted(tokens: found.map({ SmartPlaylistRules.Token.InPlaylist(playlist: $0, isTag: tag) }))
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as? SmartPlaylistRules.Token)?.representation(in: Library.shared.viewContext)
    }
    
    func tokenField(_ tokenField: NSTokenField, changedTokens tokens: [Any]) {
        delegate?.smartPlaylistRulesController?(self, changedRules: rules)
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        return tokens.map { $0 is SmartPlaylistRules.Token ? $0 : SmartPlaylistRules.Token.Search(string: $0 as! String) }
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
        let inverted = token.inverted()
        
        tokens[tokens.index(of: token)!] = inverted
        _tokenField.notifyTokenChange()
        
        _tokenField.reloadTokens()
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        delegate?.editingEnded?(smartPlaylistRulesController: self, notification: obj)
        
        if let labelField = obj.object as? TTTokenField {
            let editing = labelField.editingString
            if editing.count > 0 {
                labelField.autocomplete(with: SmartPlaylistRules.Token.Search(string: labelField.editingString))
            }
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        let labelField = control as! TTTokenField
        
        if commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
            // Use the first matching tag
            let compareSubstring = labelField.editingString.lowercased()
            
            let applicable = playlistResults(search: compareSubstring, tag: true)
            if let tag = applicable.first {
                labelField.autocomplete(with: tag)
                return true
            }
        }
        
        return false
    }
    
    @IBAction func accumulationChanged(_ sender: Any) {
        delegate?.smartPlaylistRulesController?(self, changedRules: rules)
    }
}
