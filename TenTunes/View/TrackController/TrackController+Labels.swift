//
//  TrackController+Labels.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension TrackController {
    override func cancelOperation(_ sender: Any?) {
        // TODO Move this to the Hideable Bar class
        let firstResponder = view.window?.firstResponder
        
        if firstResponder == filterController._tokenField.currentEditor() {
            filterBar.close()
        }
        else if firstResponder == smartPlaylistRuleController._tokenField.currentEditor() {
            ruleBar.close()
        }
    }
    
    @IBAction func rulesClicked(_ sender: Any) {
        if ruleBar.isOpen {
            ruleBar.close()
        }
        else {
            ruleBar.open()
            
            if ruleBar.contentView == smartPlaylistRuleController {
                view.window?.makeFirstResponder(smartPlaylistRuleController._tokenField)
            }
            else if ruleBar.contentView == smartFolderRuleController {
                view.window?.makeFirstResponder(smartFolderRuleController._tokenField)
            }
        }
    }
}

extension TrackController : SmartPlaylistRulesControllerDelegate {
    func smartPlaylistRulesController(_ controller: SmartPlaylistRulesController, changedRules rules: SmartPlaylistRules) {
        // TODO Live search
        if controller == smartPlaylistRuleController, let playlist = history.playlist as? PlaylistSmart {
            if playlist.rrules != rules {
                playlist.rules = rules
                try! Library.shared.viewContext.save()
            }
        }
        else {
            desired.filter = rules.filter(in: Library.shared.viewContext)
        }
    }
}

extension TrackController : CartesianRulesControllerDelegate {
    func cartesianRulesController(_ controller: CartesianRulesController, changedTokens tokens: [CartesianRules.Token]) {
        if controller == smartFolderRuleController, let playlist = history.playlist as? PlaylistCartesian {
            if playlist.rules.tokens != tokens {
                playlist.rules.tokens = tokens
                NSManagedObject.markDirty(playlist, \.rules)
                try! Library.shared.viewContext.save()
            }
        }
    }
}
