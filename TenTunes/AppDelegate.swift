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


    func applicationWillFinishLaunching(_ notification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack
    
    static var dataLocation: URL {
        let musicDir = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first!
        return musicDir.appendingPathComponent("Ten Tunes")
    }

    lazy var persistentContainer: Library = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = Library(name: "TenTunes", at: AppDelegate.dataLocation)
        
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    // TODO Replace?? We auto-save normally.
    @IBAction func saveAction(_ sender: AnyObject?) {
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
            
            if !ITunesImporter.importFrom(url: url, to: Library.shared) {
                let alert: NSAlert = NSAlert()
                alert.messageText = "Invalid File"
                alert.informativeText = "The selected file is not a valid iTunes library file."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    @IBAction func revealExports(_ sender: Any) {
        NSWorkspace.shared.activateFileViewerSelecting([Library.shared.exportURL(title: nil)])
    }
    
    @IBAction func refreshExports(_ sender: Any) {
        Library.shared._exportChanged = nil
    }
    
    @IBAction func openDocument(_ sender: Any) {
        let dialog = NSOpenPanel()

        dialog.allowsMultipleSelection = true

        // TODO Allow only audiovisual files
//        dialog.title                   = "Select an iTunes Library"
//        dialog.allowedFileTypes        = ["xml"]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            let tracks = dialog.urls.map { self.importFile($0) }
            
            try! Library.shared.viewContext.save()
            
            if PlayOpenedFiles.current == .play {
                ViewController.shared.player.enqueue(tracks: tracks)
                ViewController.shared.player.play(moved: 1)
            }
        }
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let tracks: [Track] = filenames.map { path in
            let url = URL(fileURLWithPath: path)
            return self.importFile(url)
        }
        
        try! Library.shared.viewContext.save()
        
        if PlayOpenedFiles.current == .play {
            ViewController.shared.player.enqueue(tracks: tracks)
            ViewController.shared.player.play(moved: 1)
        }
    }
    
    func importFile(_ url: URL) -> Track {
        let track = Track()
        
        track.path = url.absoluteString
        track.title = url.lastPathComponent
        
        Library.shared.viewContext.insert(track)
        
        return track
    }
}

