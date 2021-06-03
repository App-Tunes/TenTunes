//
//  AppDelegate.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import Preferences
import Defaults

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static let testUserDefaultsSuite = "ivorius.TenTunesTests"

    static var defaults : UserDefaults = UserDefaults.standard
    
    static let objectModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "TenTunes", withExtension: "momd")!)!

    var libraryWindowController: NSWindowController!
    
    var preferencesController: PreferencesWindowController!
    var exportPlaylistsController: ExportPlaylistsController!
    var visualizerController: VisualizerWindowController!
    
    // Otherwise, gets deallocated
    var currentWorkflow: WorkflowWindowController?
    
    var persistentContainer: Library!
    
    var launchURLs: [URL] = []
    
    var terminateProcess: Process?
    
    class var isTest : Bool {
        return (ProcessInfo.processInfo.environment["IS_TT_TEST"] as NSString?)?.boolValue ?? false
    }
    
    class var isNoReopen : Bool {
        return ProcessInfo.processInfo.arguments.contains("--no-reopen")
    }
    
    func setupBackwardsCompatibility() {
        let renamedClasses: [(AnyClass, String)] = [
            (SmartPlaylistRules.self, "TenTunes.PlaylistRules"),
            (SmartPlaylistRules.Token.InPlaylist.self, "_TtCC8TenTunes10TrackLabel10InPlaylist"),
            (SmartPlaylistRules.Token.InPlaylist.self, "_TtCCC8TenTunes18SmartPlaylistRules5Token10InPlaylist"),
            (SmartPlaylistRules.Token.MinBitrate.self, "_TtCC8TenTunes10TrackLabel10MinBitrate"),
            (SmartPlaylistRules.Token.MinBitrate.self, "_TtCCC8TenTunes18SmartPlaylistRules5Token10MinBitrate"),
            
            (CartesianRules.Token.Folder.self, "_TtCC8TenTunes13PlaylistLabel6Folder"),
            (CartesianRules.Token.Folder.self, "_TtCCC8TenTunes14CartesianRules5Token6Folder"),
        ]
        
        for (new, old) in renamedClasses {
            NSKeyedUnarchiver.setClass(new, forClassName: old)
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        if AppDelegate.isTest {
            let defaults = UserDefaults(suiteName: AppDelegate.testUserDefaultsSuite)!
            defaults.removePersistentDomain(forName: AppDelegate.testUserDefaultsSuite)
            AppDelegate.defaults = defaults
        }
        
        setupBackwardsCompatibility()
        
        ValueTransformers.register()
        Defaults.Keys.eagerLoad()
    }
    
    @discardableResult
    func tryLibrary(at location: URL, create: Bool?) -> Bool {
        persistentContainer = Library(name: "TenTunes", at: location, create: create)
        
        if let library = persistentContainer {
            if !AppDelegate.isTest {
                AppDelegate.defaults.set(Library.shared.directory, forKey: "libraryLocation")
            }
            
            if library.viewContext.hasChanges {
                try! library.viewContext.save()
            }
        }
        
        return persistentContainer != nil
    }
    
    func popLaunchTTL() -> URL? {
        return launchURLs.popFirst { $0.pathExtension == "ttl" }
    }
            
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        
		Essentia.initAlgorithms()

        // Try to get a library going
        var libraryURL: URL? = popLaunchTTL()
        
        if Self.isTest {
            // TODO Do SQL in-memory
            // If test, use test library
            libraryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        }
        else if !(NSEvent.modifierFlags.contains(.option) || Self.isNoReopen) {
            // If alt is held, don't use stored one
            libraryURL = AppDelegate.defaults.url(forKey: "libraryLocation")
                ?? Library.defaultURL()
        }

        if let libraryURL = libraryURL {
            tryLibrary(at: libraryURL, create: nil)
        }
        
        guard !Self.isTest else {
            commenceAfterWelcome()
            return
        }
        
        let welcomeWorkflow = WorkflowWindowController.create(title: "Welcome to Ten Tunes!")
        addWelcomeSteps(workflow: welcomeWorkflow, chooseLibrary: persistentContainer == nil)
        
        if !welcomeWorkflow.isEmpty {
            welcomeWorkflow.start()
            currentWorkflow = welcomeWorkflow
        }
        else {
            commenceAfterWelcome()
        }
    }
    
    func commenceAfterWelcome() {
        assert(persistentContainer != nil)
        
        let libraryStoryboard = NSStoryboard(name: .init("Library"), bundle: nil)
        libraryWindowController = (libraryStoryboard.instantiateInitialController() as! NSWindowController)
        
        preferencesController = PreferencesWindowController(preferencePanes: [
            BehaviorPreferences(),
            ViewPreferences(),
            FilesPreferences(),
        ])
        
        exportPlaylistsController = ExportPlaylistsController(windowNibName: .init("ExportPlaylistsController"))
        
        visualizerController = VisualizerWindowController(windowNibName: .init("VisualizerWindowController"))
        visualizerController.loadWindow()
        
        WindowWarden.shared.remember(window: libraryWindowController.window!, key: ("0", .command))
        WindowWarden.shared.remember(window: visualizerController.window!, key: ("t", .command), toggleable: true)
        
        if !launchURLs.isEmpty {
            self.import(urls: launchURLs)
            launchURLs = []
        }
        
        // Initially check on every launch
        Library.shared.checkSanity()
                
        libraryWindowController.window!.makeKeyAndOrderFront(self)
    }
        
    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard ViewController.shared != nil else {
            return .terminateNow // We aren't fully launched yet anyway! Who the fuck cares!
        }
        
        let runningTasks = ViewController.shared.runningTasks
        let tasksPreventingQuit = (ViewController.shared.tasker.queue + runningTasks).filter { $0.preventsQuit }
        
        // TODO Live update this
        guard NSAlert.ensure(intent: tasksPreventingQuit.isEmpty, action: "Running Tasks", text: "There are currently still \(tasksPreventingQuit.count) tasks running. Do you want to quit anyway?") else {
            return .terminateCancel
        }
        
        ViewController.shared.tasker.queue.clear()
        // Try to cancel to speed up quitting
        for task in runningTasks {
            task.cancel()
        }
        
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        terminateProcess?.launch()
    }
        
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard ViewController.shared != nil else {
            // Not set up yet
            return true
        }
        
        if !flag {
            ViewController.shared.view.window?.makeKeyAndOrderFront(self)
        }
        
        return true
    }
}

extension AppDelegate : NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

