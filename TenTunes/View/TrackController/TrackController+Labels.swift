//
//  TrackController+Labels.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension TrackController : TrackLabelControllerDelegate {
    func labelsChanged(labelManager: TrackLabelController, labels: [Label]) {
        // TODO Live search
        if labelManager == ruleController, let playlist = history.playlist as? PlaylistSmart {
            if playlist.rules.labels != labels {
                playlist.rules.labels = labels
                NSManagedObject.markDirty(playlist, \.rules)
                try! Library.shared.viewContext.save()
            }
        }
        else {
            desired.filter = PlaylistRules(labels: labels).filter(in: Library.shared.viewContext)
        }
    }
    
    override func cancelOperation(_ sender: Any?) {
        // TODO Move this to the Hideable Bar class
        let firstResponder = view.window?.firstResponder
        
        if firstResponder == filterController._labelField.currentEditor() {
            filterBar.close()
        }
        else if firstResponder == ruleController._labelField.currentEditor() {
            ruleBar.close()
        }
    }

    @IBAction func rulesClicked(_ sender: Any) {
        if ruleBar.isOpen {
            ruleBar.close()
        }
        else {
            ruleBar.open()
            view.window?.makeFirstResponder(ruleController._labelField)
        }
    }
}
