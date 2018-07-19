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
            if playlist.labels != labels {
                playlist.labels = labels
                try! Library.shared.viewContext.save()
            }
        }
        else {
            desired.filter = PlaylistSmart.filter(of: labels)
        }
    }
    
    override func cancelOperation(_ sender: Any?) {
        let firstResponder = view.window?.firstResponder
        
        if firstResponder == _tagField {
            _searchBarClose.performClick(self)
        }
        else if firstResponder == _ruleField {
            _ruleBarClose.performClick(self)
        }
    }
    
    @IBAction func closeSearchBar(_ sender: Any) {
        desired.filter = nil
        
        _tagField.resignFirstResponder()
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _tagBarHeight.animator().constant = 0
        })
        view.window?.makeFirstResponder(view)
    }
    
    @IBAction func closeRuleBar(_ sender: Any) {
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
            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.2
                _ruleBarHeight.animator().constant = 28
            })
            _ruleField.window?.makeFirstResponder(_ruleField)
        }
    }
}
