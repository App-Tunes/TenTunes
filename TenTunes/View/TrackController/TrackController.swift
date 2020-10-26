//
//  TrackController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

import AVFoundation
import Defaults

@objc class PlayHistorySetup : NSObject {
    override init() {
    }
    
    var _changed = false {
        didSet { isDone = isDone && !_changed }
    }
    @objc dynamic var isDone = true

    var playlist: AnyPlaylist? {
        didSet { _changed = _changed || oldValue !== playlist }
    }

    var filter: ((Track) -> Bool)? {
        didSet { _changed = _changed || oldValue != nil || filter != nil }
    }
    
    var sort: ((Track, Track) -> Bool)? {
        didSet { _changed = _changed || oldValue != nil || sort != nil }
    }
}

class TrackController: NSViewController {
    static let smallRowHeight: CGFloat = 20
    static let libraryAutosaveName = "tracks"
    static let queueAutosaveName = "libraryQueue"

    @IBOutlet var _tableView: ActionTableView!
    @IBOutlet var _tableViewHeight: NSLayoutConstraint!
    var tableViewHiddenExtension: NSTableView.ColumnHiddenExtension!
    var tableViewSynchronizer: NSTableView.ActiveSynchronizer!

    @IBOutlet var filterController: SmartPlaylistRulesController!
    @IBOutlet var filterBar: HideableBar!
    @IBOutlet var _filterBarContainer: NSView!

    @IBOutlet var smartPlaylistRuleController: SmartPlaylistRulesController!
    @IBOutlet var smartFolderRuleController: CartesianRulesController!
    @IBOutlet var ruleBar: HideableBar!
    @IBOutlet var _ruleBarContainer: NSView!
    @IBOutlet var _ruleButton: NSButton!
    
    @IBOutlet var _playlistTitle: NSTextField!
    @IBOutlet var _playlistIcon: NSImageView!
    @IBOutlet var _playlistInfoBarHeight: NSLayoutConstraint!
    
    var dragHighlightView: DragHighlightView!
    
    var trackEditor : TrackEditor!
    @IBOutlet var trackEditorGuard : MultiplicityGuardView!

    var history: PlayHistory = PlayHistory(playlist: PlaylistEmpty()) {
        didSet {
            _tableView?.animateDifference(from: oldValue.tracks, to: history.tracks)
            self.reloadGUI()
        }
    }
    @objc dynamic var desired: PlayHistorySetup = PlayHistorySetup()
    @IBOutlet var _loadingIndicator: NSProgressIndicator!
    @IBOutlet var _emptyIndicator: NSImageView!
    
    var mode: Mode = .tracksList
        
    @IBOutlet var _trackCounter: NSTextField!
    
    var observeHiddenToken: NSKeyValueObservation?
    var observeTrackWord: [DefaultsObservation] = []
    
    var trackActions: TrackActions?

    enum Mode {
        case tracksList, queue, title
    }

    override func awakeFromNib() {
        observeHiddenToken = desired.observe(\.isDone, options: [.new, .initial]) { [unowned self] object, change in
            guard self.mode != .title else {
                return
            }
            
            let isDone = change.newValue!
            
            if !isDone {
                self._loadingIndicator.startAnimation(self)
            }

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                self._loadingIndicator.animator().alphaValue = isDone ? 0 : 1
            }) {
                if isDone && self.desired.isDone { self._loadingIndicator.stopAnimation(self) }
            }
        }

        trackEditor = TrackEditor(nibName: .init("TrackEditor"), bundle: nil)
        trackEditor.loadView()
        
        trackEditorGuard.delegate = self
        trackEditorGuard.contentView = trackEditor.view
        trackEditorGuard.present(elements: [])
        
        _playlistTitle.stringValue = ""
        
        filterBar = HideableBar(nibName: .init("HideableBar"), bundle: nil)
        filterBar.height = 32
        filterBar.delegate = self
        _filterBarContainer.setFullSizeContent(filterBar.view)
        
        filterController = SmartPlaylistRulesController(nibName: .init("SmartPlaylistRulesController"), bundle: nil)
        filterController.delegate = self
        filterBar.contentView = filterController.view

        ruleBar = HideableBar(nibName: .init("HideableBar"), bundle: nil)
        ruleBar.height = 32
        ruleBar.delegate = self
        _ruleBarContainer.setFullSizeContent(ruleBar.view)

        smartPlaylistRuleController = SmartPlaylistRulesController(nibName: .init("SmartPlaylistRulesController"), bundle: nil)
        smartPlaylistRuleController.delegate = self
        ruleBar.contentView = smartPlaylistRuleController.view
        
        smartFolderRuleController = CartesianRulesController(nibName: .init("CartesianRulesController"), bundle: nil)
        smartFolderRuleController.delegate = self
        smartFolderRuleController.loadView()

        dragHighlightView = DragHighlightView.add(to: _loadingIndicator.superview!)
        dragHighlightView.registerForDraggedTypes(TrackPromise.pasteboardTypes)
        dragHighlightView.delegate = self
                
        initTable()
        
        registerObservers()
    }
    
    override func viewDidAppear() {
        _tableView.backgroundColor = NSColor.clear

        // Appearance is not yet set in willappear
        if mode == .tracksList {
            _tableView.enclosingScrollView?.backgroundColor = view.byAppearance([
                nil: NSColor(white: 0.73, alpha: 1.0),
                .vibrantDark: NSColor(white: 0.09, alpha: 1.0),
            ])

            if #available(OSX 10.14, *) {
                _tableView.headerView?.vibrancyView?.material = .underWindowBackground
            }
        }
    }
        
    func libraryfy() {
        _tableView.autosaveName = Self.libraryAutosaveName
        tableViewHiddenExtension.attach()
        tableViewSynchronizer.attach()
    }
    
    func queueify() {
        mode = .queue
        
        // TODO Auto-update title when editing queue
        // TODO Auto-scroll is not far enough up (stops just short) if title is shown
        _tableView.autosaveName = Self.queueAutosaveName
        tableViewHiddenExtension.attach()
        tableViewSynchronizer.attach()
        
        _tableView.enclosingScrollView?.drawsBackground = false
        _tableView.enclosingScrollView?.backgroundColor = NSColor.clear
        _tableView.usesAlternatingRowBackgroundColors = false  // TODO In NSPanels, this is solid while everything else isn't
        trackEditorGuard.removeFromSuperview()
        
        self._loadingIndicator.isHidden = true
        observeHiddenToken = nil // We don't want loading animations round here
        
        _tableView.sizeToFit()
    }
    
    func titleify() {
        queueify()
        mode = .title

        _tableView.headerView = nil

        _playlistInfoBarHeight.constant = 0
        _tableViewHeight.constant = 0
        _tableView.enclosingScrollView?.hasVerticalScroller = false
        _tableView.enclosingScrollView?.hasHorizontalScroller = false
        _tableView.enclosingScrollView?.verticalScrollElasticity = .none
        _tableView.enclosingScrollView?.horizontalScrollElasticity = .none
    }
    
    func show(tokens: [SmartPlaylistRules.Token]) {
        filterBar.open()
        filterController.rules = SmartPlaylistRules(tokens: tokens)
    }
}

extension TrackController : HideableBarDelegate {
    func hideableBar(_ bar: HideableBar, didChangeState state: Bool) {
        if bar == ruleBar {
            _ruleButton.state = state ? .on : .off
        }
        else if bar == filterBar {
            desired.filter = state ? filterController.rules.filter(in: Library.shared.viewContext) : nil
            
            // TODO Too omniscient, let ViewController observe it itself
            ViewController.shared._find.state = state ? .on : .off
        }
        
        if !(view.window?.hasFirstResponder ?? true) {
            // It was probably the bar, but who cares, it's freeee
            view.window?.makeFirstResponder(_tableView)
        }
    }
}

extension TrackController : MultiplicityGuardDelegate {
    func multiplicityGuard(_ view: MultiplicityGuardView, show elements: [Any]) -> MultiplicityGuardView.ShowAction {
        let tracks = elements as! [Track]
        guard tracks.allSatisfy({ $0.liveURL != nil }) else {
            return .error(text: String(format: "%@ Not Found", AppDelegate.defaults[.trackWordSingular].capitalized))
        }
        
        trackEditor!.show(tracks: tracks)
        return .show
    }
}

extension TrackController : NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return subview == trackEditorGuard
    }
}
