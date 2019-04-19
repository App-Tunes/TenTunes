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

    var welcomeController: WelcomeWindowController!

    var libraryWindowController: NSWindowController!
    
    var preferencesController: PreferencesWindowController!
    var exportPlaylistsController: ExportPlaylistsController!
    var visualizerController: VisualizerWindowController!
    
    var persistentContainer: Library!
    
    class var isTest : Bool {
        return (ProcessInfo.processInfo.environment["IS_TT_TEST"] as NSString?)?.boolValue ?? false
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
    
    func chooseLibrary(_ url: URL? = nil) {
        var location: URL! = url
            ?? AppDelegate.defaults.url(forKey: "libraryLocation")
            ?? Library.defaultURL()
        
        var create: Bool?
        var freedomToChoose = NSEvent.modifierFlags.contains(.option)
        
        if AppDelegate.isTest {
            // TODO Do SQL in-memory
            location = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            persistentContainer = Library(name: "TenTunes", at: location, create: create)
        }
        
        while persistentContainer == nil {
            if freedomToChoose {
                switch NSAlert.choose(title: "Choose Library", text: "Please choose or create a library location. This is where your data and music are stored.", actions: ["Choose Existing", "New Library", "Cancel", ]) {
                case .alertSecondButtonReturn:
                    let dialog = NSSavePanel()
                    
                    location = dialog.runModal() == .OK ? dialog.url : nil
                    create = true
                case .alertFirstButtonReturn:
                    let dialog = NSOpenPanel()
                    
                    dialog.canChooseFiles = true // packages are considered files by finder, library is a package
                    dialog.canChooseDirectories = true
                    dialog.allowedFileTypes = ["de.ivorius.tentunes.library"]
                    dialog.directoryURL = location
                    
                    location = dialog.runModal() == .OK ? dialog.url : nil
                    create = false
                default:
                    NSApp.terminate(self)
                }
            }
            
            guard location != nil else {
                NSApp.terminate(self)
                return
            }
            
            persistentContainer = Library(name: "TenTunes", at: location, create: create)
            
            if persistentContainer == nil {
                NSAlert.informational(title: "Failed to load library", text: "The library could not be read or created anew. Please use a different library location.")
                freedomToChoose = true
            }
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        
        if persistentContainer == nil {
            chooseLibrary()
        }
        AppDelegate.defaults.set(Library.shared.directory, forKey: "libraryLocation")
        
        welcomeController = WelcomeWindowController(windowNibName: .init("WelcomeWindowController"))
        
        let libraryStoryboard = NSStoryboard(name: .init("Library"), bundle: nil)
        libraryWindowController = (libraryStoryboard.instantiateInitialController() as! NSWindowController)
        
        preferencesController = PreferencesWindowController(viewControllers: [
            BehaviorPreferences(),
            ViewPreferences(),
            FilesPreferences(),
            ])
        
        exportPlaylistsController = ExportPlaylistsController(windowNibName: .init("ExportPlaylistsController"))
        
        visualizerController = VisualizerWindowController(windowNibName: .init("VisualizerWindowController"))
        visualizerController.loadWindow()
        
        WindowWarden.shared.remember(window: libraryWindowController.window!, key: ("0", .command))
        WindowWarden.shared.remember(window: visualizerController.window!, key: ("t", .command), toggleable: true)
        
        if !AppDelegate.isTest && AppDelegate.defaults.consume(toggle: "WelcomeWindow") {
            welcomeController.showWindow(self)
        }
        else {
            commenceAfterWelcome()
        }
    }
    
    func commenceAfterWelcome() {
        #if !DEBUG
        SuperpoweredSplash.show(in: (libraryWindowController.contentViewController as! ViewController)._trackGuardView.superview!.superview!)
        #endif
        
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
        
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
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

