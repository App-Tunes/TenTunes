//
//  AppDelegate.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 17.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var libraryWindowController: NSWindowController!
    
    var preferencesController: PreferencesWindowController!
    var exportPlaylistsController: ExportPlaylistsController!
    var visualizerController: VisualizerWindowController!
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        setupBackwardsCompatibility()
        
        ValueTransformers.register()
        UserDefaults.standard.register(defaults: NSDictionary(contentsOf: Bundle.main.url(forResource: "DefaultPreferences", withExtension: "plist")!) as! [String : Any])

        var location: URL!
        var create: Bool?
        
        let defaultURL = { () -> URL in
            if let previous = UserDefaults.standard.url(forKey: "libraryLocation") {
                return previous
            }
            
            let musicDir = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first!
            return musicDir.appendingPathComponent("Ten Tunes")
        }
        
        var freedomToChoose = NSEvent.modifierFlags.contains(.option)

        while persistentContainer == nil {
            if freedomToChoose {
                switch NSAlert.choose(title: "Choose Library", text: "Please choose or create a library location. This is where your data and music are stored.", actions: ["Choose Existing", "New Library", "Cancel", ]) {
                case .alertSecondButtonReturn:
                    let dialog = NSSavePanel()
                    
                    location = dialog.runModal() == .OK ? dialog.url : nil
                    create = true
                case .alertFirstButtonReturn:
                    let dialog = NSOpenPanel()
                    
                    dialog.canChooseFiles = false
                    dialog.canChooseDirectories = true
                    dialog.directoryURL = defaultURL()
                    
                    location = dialog.runModal() == .OK ? dialog.url : nil
                    create = false
                default:
                    NSApp.terminate(self)
                }
            }
            else {
                location = defaultURL()
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
        
        UserDefaults.standard.set(location, forKey: "libraryLocation")
        
        let libraryStoryboard = NSStoryboard(name: .init("Library"), bundle: nil)
        libraryWindowController = (libraryStoryboard.instantiateInitialController() as! NSWindowController)
        
        preferencesController = PreferencesWindowController(windowNibName: .init(rawValue: "PreferencesWindowController"))
        
        exportPlaylistsController = ExportPlaylistsController(windowNibName: .init(rawValue: "ExportPlaylistsController"))
        
        visualizerController = VisualizerWindowController(windowNibName: .init("VisualizerWindowController"))
        visualizerController.loadWindow()
        
        WindowWarden.shared.remember(window: libraryWindowController.window!, key: ("0", .command))
        WindowWarden.shared.remember(window: visualizerController.window!, key: ("t", .command), toggleable: true)

        libraryWindowController.window!.makeKeyAndOrderFront(self)
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

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSUserNotificationCenter.default.delegate = self
    }

    // MARK: - Core Data stack
    
    var persistentContainer: Library!
    
    // MARK: - Core Data Saving and Undo support

    // TODO Replace?? We auto-save normally.
    @IBAction func saveDocument(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
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

    @IBAction func importFromITunes(_ sender: Any) {
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Select an iTunes Library"
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["xml"]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            guard let url = dialog.url else {
                return
            }
            
            if !Library.shared.import().iTunesLibraryXML(url: url) {
                let alert: NSAlert = NSAlert()
                alert.messageText = "Invalid File"
                alert.informativeText = "The selected file is not a valid iTunes library file."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            
            if UserDefaults.standard.consume(toggle: "iTunesImportTutorial") {
                NSAlert.tutorial(topic: "iTunes Import", text: "On iTunes imports, imported tracks will not be automatically moved to your media directory.")
            }
        }
    }
    
    @IBAction func revealExports(_ sender: Any) {
        NSWorkspace.shared.activateFileViewerSelecting([Library.shared.export().url(title: nil)])
    }
    
    @IBAction func refreshExports(_ sender: Any) {
        Library.shared._exportChanged = nil
    }
    
    @IBAction func exportPlaylists(_ sender: Any) {
        exportPlaylistsController.showWindow(self)
    }
    
    @IBAction
    func showPreferences(sender: Any?) {
        preferencesController.showWindow(self)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            ViewController.shared.view.window?.makeKeyAndOrderFront(self)
        }
        
        return true
    }
    
    @IBAction func openDocument(_ sender: Any) {
        let dialog = Library.Import.dialogue(allowedFiles: Library.FileTypes.all)


        // TODO Allow only audiovisual files, and m3u
//        dialog.title                   = "Select an iTunes Library"
//        dialog.allowedFileTypes        = ["xml"]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            self.import(urls: dialog.urls)
        }
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        self.import(urls: urls)
    }
    
    func `import`(urls: [URL]) {
        let objects = urls.compactMap { Library.shared.import().guess(url: $0) }
        
        try! Library.shared.viewContext.save()
        
        if UserDefaults.standard.consume(toggle: "fileImportTutorial") {
            NSAlert.tutorial(topic: "Importing Tracks", text: "When adding tracks to your library, the files will automatically be copied to your media directory. You can change this behavior in the preferences.")
        }

        let tracks = objects.compactMap { $0 as? Track }
        if tracks.count > 0, Preferences.PlayOpenedFiles.current == .play {
            ViewController.shared.player.enqueue(tracks: tracks)
            ViewController.shared.player.play(moved: 1)
        }
    }
    
    @IBAction
    func refreshMetadata(sender: Any?) {
        for track in Library.shared.allTracks.tracksList {
            track.metadataFetchDate = nil
        }
        
        try! Library.shared.viewContext.save()
    }
}

extension AppDelegate : NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

