//
//  HideableBar.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol HideableBarDelegate {
    func hideableBar(_ bar: HideableBar, didChangeState state: Bool)
}

class HideableBar: NSViewController {

    @IBOutlet var _containerView: NSView!
    @IBOutlet var _closeButton: NSButton!
    
    @IBOutlet var _heightConstraint: NSLayoutConstraint!
    
    @IBOutlet var contentView : NSView? {
        didSet { _containerView.setFullSizeContent(contentView) }
    }
    
    var delegate: HideableBarDelegate?
    
    override func awakeFromNib() {
        _heightConstraint.constant = 0
    }
    
    var isOpen: Bool {
        return _heightConstraint.constant > 0
    }
    
    var height: CGFloat = 30
    
    func open() {
        guard !isOpen else {
            return
        }
        
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _heightConstraint.animator().constant = height
        })
        
        delegate?.hideableBar(self, didChangeState: true)
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        guard isOpen else {
            return
        }
        
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _heightConstraint.animator().constant = 0
        })
        
        delegate?.hideableBar(self, didChangeState: false)
    }
    
    func close() { // TODO Resign first responder for any subviews
        _closeButton.performClick(self)
    }
}
