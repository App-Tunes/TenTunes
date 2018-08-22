//
//  CartesianRulesController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc protocol CartesianRulesControllerDelegate {
    @objc optional func cartesianRulesController(_ controller: CartesianRulesController, changedTokens tokens: [CartesianRules.Token])
    
    @objc optional func editingEnded(cartesianRulesController: CartesianRulesController, notification: Notification)
}

class CartesianRulesController : NSViewController, TTTokenFieldDelegate {
    @IBOutlet @objc weak open var delegate: CartesianRulesControllerDelegate?
    
    @IBOutlet var _tokenField: TTTokenField!
    
    var tokens: [CartesianRules.Token] {
        get { return _tokenField.tokens as! [CartesianRules.Token] }
        set { _tokenField.tokens = newValue }
    }
    
    var folders: [PlaylistFolder] {
        return Library.shared.allPlaylists().compactMap { $0 as? PlaylistFolder}
    }
    
    func tokenField(_ tokenField: NSTokenField, completionGroupsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [TTTokenField.TokenGroup]? {
        let compareSubstring = substring.lowercased()
        
        var groups: [TTTokenField.TokenGroup] = []

        groups.append(.init(title: "Folder", contents: folderResults(search: compareSubstring)))
        
        return groups
    }
    
    static func sorted<L : CartesianRules.Token>(tokens: [L]) -> [L] {
        return tokens.sorted { (a, b) -> Bool in
            a.representation(in: Library.shared.viewContext).count < b.representation(in: Library.shared.viewContext).count
        }
    }
    
    func folderResults(search: String) -> [CartesianRules.Token] {
        let found = search.count > 0 ? folders.filter({ $0.name.lowercased().range(of: search) != nil }) : folders
        return CartesianRulesController.sorted(tokens: found.map({ .Folder(playlist: $0) }))
    }
    
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        return (representedObject as? CartesianRules.Token)?.representation(in: Library.shared.viewContext)
    }
    
    func tokenField(_ tokenField: NSTokenField, changedTokens tokens: [Any]) {
        delegate?.cartesianRulesController?(self, changedTokens: self.tokens)
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        return tokens.compactMap {
            if $0 is CartesianRules.Token {
                return $0
            }
            else if let substring = $0 as? String {
                let compareSubstring = substring.lowercased()
                
                let applicable = folderResults(search: compareSubstring)
                if let tag = applicable.first { return tag }
            }
            
            return nil
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        delegate?.editingEnded?(cartesianRulesController: self, notification: obj)
        (obj.object as? TTTokenField)?.autocomplete(with: nil)
    }
}
