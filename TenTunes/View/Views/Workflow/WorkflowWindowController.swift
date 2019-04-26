//
//  WorkflowWindowController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

class WorkflowWindowController: NSWindowController {
    var _steps: [NSViewController] = []
    var _currentStep = 0
    
    var _inset: CGFloat = 5000
    
    @IBOutlet var _scrollView: NSScrollView!
    
    static func create(title: String, steps: [NSViewController]) -> WorkflowWindowController {
        let controller = WorkflowWindowController(windowNibName: .init("WorkflowWindowController"))
        controller.loadWindow()
        
        controller.title = title
        steps.forEach(controller.addStep)
        
        return controller
    }
    
    static func next(_ view: NSView) {
        let controller = view.window!.windowController as! WorkflowWindowController
        controller.next()
    }
    
    var isDone: Bool {
        return _currentStep == _steps.count - 1
    }
    
    var title: String {
        get { return window!.title }
        set { window!.title = newValue }
    }
    
    func container(forStep step: NSViewController) -> DisablableView {
        return step.view.superview! as! DisablableView
    }
    
    func container(forStepAt idx: Int) -> DisablableView {
        return container(forStep: _steps[idx])
    }
    
    func start() {
        let container = _scrollView.documentView!
        let clip = _scrollView.contentView
        
        _inset = clip.frame.size.width
        
        // Only auto-resize with width
        container.subviews.removeAll()
        container.translatesAutoresizingMaskIntoConstraints = false
        clip.addConstraints([
            NSLayoutConstraint(item: container, attribute: .leading, relatedBy: .equal, toItem: clip, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: container, attribute: .trailing, relatedBy: .equal, toItem: clip, attribute: .trailing, multiplier: 1, constant: 0),
            ])
        
        var previous: NSView? = nil
        for step in _steps {
            let view = DisablableView()
            
            view.addSubview(step.view)
            view.setFullSizeContent(step.view)
            
            view.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(view)
            
            container.addConstraints([
                NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1, constant: 0),
                
                NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: previous ?? container, attribute: previous == nil ? .top : .bottom, multiplier: 1, constant: previous == nil ? _inset : 0),
                ])
            
            previous = view
        }
        
        if let previous = previous {
            container.addConstraint(
                NSLayoutConstraint(item: previous, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1, constant: -_inset)
            )
        }
        
        showWindow(self)
    }
    
    func addStep(_ step: NSViewController) {
        _steps.append(step)
    }
    
    func next() {
        _currentStep += 1
        
        scrollToCurrentStep()
    }
    
    func scrollToCurrentStep(instant: Bool = false) {
        _steps.map(container).enumerated().forEach { (idx, view) in
            view.isEnabled = _currentStep == idx
        }

        let target = container(forStepAt: _currentStep)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = instant ? 0 : .seconds(0.5)
            
            let containerHeight = _scrollView.contentView.frame.size.height
            _scrollView.contentView.animator().bounds.origin.y = target.frame.midY - containerHeight / 2
        }
    }
}

@IBDesignable
@objc(BCLDisablableScrollView)
public class DisablableScrollView: NSScrollView {
    @IBInspectable
    @objc(enabled)
    public var isEnabled: Bool = true
    
    public override func scrollWheel(with event: NSEvent) {
        if isEnabled {
            super.scrollWheel(with: event)
        }
        else {
            nextResponder?.scrollWheel(with: event)
        }
    }
}

@objc(BCLDisablableView)
public class DisablableView: NSView {
    let _disabler = NSView()
    
    public var isEnabled: Bool {
        set {
            _disabler.isHidden = newValue
            self.alphaValue = newValue ? 1.0 : 0.7
        }
        get { return _disabler.isHidden }
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        createDisabler()
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        createDisabler()
    }
    
    private func createDisabler() {
        addConstraints(NSLayoutConstraint.copyLayout(from: self, for: _disabler))
        addSubview(_disabler, positioned: .above, relativeTo: nil)
    }
    
    public override func hitTest(_ point: NSPoint) -> NSView? {
        return isEnabled ? super.hitTest(point) : nil
    }
}

extension WorkflowWindowController : NSWindowDelegate {
    func windowDidChangeOcclusionState(_ notification: Notification) {
        scrollToCurrentStep(instant: true)
    }
}
