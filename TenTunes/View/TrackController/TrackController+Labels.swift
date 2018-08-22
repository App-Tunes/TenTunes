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
        
        if firstResponder == filterController._labelField.currentEditor() {
            filterBar.close()
        }
        else if firstResponder == smartPlaylistRuleController._labelField.currentEditor() {
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
                view.window?.makeFirstResponder(smartPlaylistRuleController._labelField)
            }
            else if ruleBar.contentView == smartFolderRuleController {
                view.window?.makeFirstResponder(smartFolderRuleController._labelField)
            }
        }
    }
}

extension TrackController : TrackLabelControllerDelegate {
    func labelsChanged(trackLabelController: SmartPlaylistRulesController, rules: SmartPlaylistRules) {
        // TODO Live search
        if trackLabelController == smartPlaylistRuleController, let playlist = history.playlist as? PlaylistSmart {
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

extension TrackController : CartesianLabelControllerDelegate {
    func labelsChanged(cartesianLabelController: CartesianLabelController, labels: [CartesianRules.Token]) {
        if cartesianLabelController == smartFolderRuleController, let playlist = history.playlist as? PlaylistCartesian {
            if playlist.rules.labels != labels {
                playlist.rules.labels = labels
                NSManagedObject.markDirty(playlist, \.rules)
                try! Library.shared.viewContext.save()
            }
        }
    }
}
