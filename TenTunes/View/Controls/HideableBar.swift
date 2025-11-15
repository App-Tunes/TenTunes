//
//  HideableBar.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol HideableBarDelegate : AnyObject {
    func hideableBar(_ bar: HideableBar, didChangeState state: Bool)
}

class HideableBar: NSViewController {

    @IBOutlet var _containerView: NSView!
    @IBOutlet var _closeButton: NSButton!
    
    @IBOutlet var _heightConstraint: NSLayoutConstraint!
    
    @IBOutlet var contentView : NSView? {
        didSet {
            if oldValue != contentView {
                _containerView.setFullSizeContent(contentView)
            }
        }
    }
    
    weak var delegate: HideableBarDelegate?
    
    override func awakeFromNib() {
        _heightConstraint.constant = 0
		_containerView.clipsToBounds = true
		view.isHidden = true
    }
    
    var isOpen: Bool {
        // Take current wanted value
        return _heightConstraint.animator().constant > 0
    }
    
    var height: CGFloat = 30
    
    func open() {
        guard !isOpen else {
            return
        }
        
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.2
            _heightConstraint.animator().constant = height
			view.isHidden = false
        })
        
        delegate?.hideableBar(self, didChangeState: true)
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        close()
    }
    
    func close() {
        if view.isInWindowResponderChain {
            view.window?.makeFirstResponder(nil)
        }
        
        guard isOpen else {
            return
        }
        
        NSAnimationContext.runAnimationGroup {_ in
            NSAnimationContext.current.duration = 0.2
            _heightConstraint.animator().constant = 0
			view.isHidden = true
        }
        
        delegate?.hideableBar(self, didChangeState: false)
    }
}
