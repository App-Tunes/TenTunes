//
//  WorkflowWindowController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

protocol WorkflowAware {
    func takeFocus()
    func resignFocus()
}

class WorkflowWindowController: NSWindowController {
    var _steps: [Step] = []
    var _currentStep = 0
    
    var _inset: CGFloat = 0
    
    @IBOutlet var _scrollView: NSScrollView!
    
    var topConstraint: NSLayoutConstraint? = nil
    var bottomConstraint: NSLayoutConstraint? = nil

    static func create(title: String, steps: [Step] = []) -> WorkflowWindowController {
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
    
    func container(forStep step : Step) -> DisablableView? {
        switch  step {
        case .interaction(let controller):
            return controller.view.superview! as? DisablableView
        default:
            return nil
        }
    }
    
    func layoutIfNeeded() {
        guard let window = window, window.isVisible else {
            return
        }
        
        window.layoutIfNeeded()
        scrollToCurrentStep(instant: true)
    }
    
    func start() {
        let container = _scrollView.documentView!
        let clip = _scrollView.contentView

        _currentStep = 0

        // Only auto-resize with width
        container.translatesAutoresizingMaskIntoConstraints = false
        clip.addConstraints([
            NSLayoutConstraint(item: container, attribute: .leading, relatedBy: .equal, toItem: clip, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: container, attribute: .trailing, relatedBy: .equal, toItem: clip, attribute: .trailing, multiplier: 1, constant: 0),
        ])
        
        showWindow(self)
        window!.center()
        
        layoutIfNeeded()
    }
    
    var isEmpty: Bool {
        return _steps.isEmpty
    }
    
    func addStep(_ step: Step) {
        switch step {
        case .interaction(let controller):
            let container = _scrollView.documentView!
            
            let previous: NSView? = _steps.compactMap(self.container).last
            let view = DisablableView()
            
            view.addSubview(controller.view)
            view.setFullSizeContent(controller.view)
            
            view.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(view)
            
            let top = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: previous ?? container, attribute: previous == nil ? .top : .bottom, multiplier: 1, constant: previous == nil ? _inset : 0)
            container.addConstraints([
                NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1, constant: 0),
                top
            ])
            if previous == nil { topConstraint = top }

            if let bottomConstraint = bottomConstraint {
                container.removeConstraint(bottomConstraint)
            }
            
            bottomConstraint = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1, constant: -_inset)
            container.addConstraint(bottomConstraint!)
        default:
            break
        }
        
        _steps.append(step)
        
        layoutIfNeeded()
    }
    
    func addSteps(_ steps: [Step]) {
        steps.forEach(addStep)
    }
    
    func next() {
        switch _steps[_currentStep] {
        case .interaction(let controller):
            (controller as? WorkflowAware)?.resignFocus()
        default:
            break
        }
        
        while _currentStep < _steps.count - 1 {
            _currentStep += 1
            
            let step = _steps[_currentStep]
            switch step {
            case .interaction:
                scrollToCurrentStep()
                return
            case .task(let task):
                task()
            }
        }
    }
    
    func scrollToCurrentStep(instant: Bool = false) {
        let clip = _scrollView.contentView

        _steps
            .enumerated()
            .forEach { (idx, step) in
                (self.container(forStep: step))?.isEnabled = _currentStep == idx
        }
        
        // Need to set this since the window sometimes changes height
        _inset = clip.frame.size.width
        topConstraint?.constant = _inset
        bottomConstraint?.constant = -_inset

        // God knows why it sometimes doesn't play along
        _scrollView.magnification = 1
        _scrollView.minMagnification = 1
        _scrollView.maxMagnification = 1

        guard let viewStepIdx = (_steps[0 ... _currentStep].lastIndex {
            Enumerations.is($0, ofType: Step.interaction)
        }) else {
            return
        }

        let viewStep = _steps[viewStepIdx]
        if viewStepIdx == _currentStep {
            (Enumerations.associatedValue(of: viewStep, as: Step.interaction)
                as? WorkflowAware)?.takeFocus()
        }
        
        let target = container(forStep: viewStep)!
        NSAnimationContext.runAnimationGroup { context in
            context.duration = instant ? 0 : .seconds(0.5)
            
            let containerHeight = _scrollView.contentView.frame.size.height
            _scrollView.contentView.animator().bounds.origin.y = target.frame.midY - containerHeight / 2
        }
    }
    
    enum Step {
        case task(_ task: () -> Void)
        case interaction(_ controller: NSViewController)
    }
}

@IBDesignable
@objc(BCLDisablableScrollView)
public class DisablableScrollView: NSScrollView {
    @IBInspectable
    @objc(isEnabled)
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
            self.alphaValue = newValue ? 1.0 : 0.5
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
    
    public override func keyDown(with event: NSEvent) {
        guard isEnabled else {
            return
        }
        super.keyDown(with: event)
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
