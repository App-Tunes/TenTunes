//
//  TrackController+Labels.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension TrackController : LabelManagerDelegate {
    func labelsChanged(labelManager: LabelManager, labels: [Label]) {
        // TODO Live search
        if labelManager == _ruleManager, let playlist = history.playlist as? PlaylistSmart {
            if playlist.rules.labels != labels {
                playlist.rules.labels = labels
                NSManagedObject.markDirty(playlist, \.rules)
                try! Library.shared.viewContext.save()
            }
        }
        else {
            desired.filter = PlaylistRules(labels: labels).filter
        }
    }
    
    override func cancelOperation(_ sender: Any?) {
        let firstResponder = view.window?.firstResponder
        
        if firstResponder == _tagField.currentEditor() {
            _searchBarClose.performClick(self)
        }
        else if firstResponder == _ruleField.currentEditor() {
            _ruleBarClose.performClick(self)
        }
    }
    
    @IBAction func closeSearchBar(_ sender: Any) {
        guard _tagBarHeight.constant > 0 else {
            return
        }
        
        desired.filter = nil
        
        _ruleButton.state = .off

        _tagField.resignFirstResponder()
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _tagBarHeight.animator().constant = 0
        })
        view.window?.makeFirstResponder(view)
    }
    
    @IBAction func closeRuleBar(_ sender: Any) {
        guard _ruleBarHeight.constant > 0 else {
            return
        }
        
        _ruleField.resignFirstResponder()
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _ruleBarHeight.animator().constant = 0
        })
        view.window?.makeFirstResponder(view)
    }

    @IBAction func rulesClicked(_ sender: Any) {
        if _ruleBarHeight.constant > 0 {
            _ruleBarClose.performClick(self)
        }
        else {
            _ruleButton.state = .on
            
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.2
                _ruleBarHeight.animator().constant = 28
            })
            _ruleField.window?.makeFirstResponder(_ruleField)
        }
    }
}
