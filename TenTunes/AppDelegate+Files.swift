//
//  AppDelegate+Files.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 15.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension AppDelegate {
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
            
            if AppDelegate.defaults.consume(toggle: "iTunesImportTutorial") {
                NSAlert.tutorial(topic: "iTunes Import", text: "On iTunes imports, imported tracks will not be automatically moved to your media directory.")
            }
        }
    }

    @IBAction func openDocument(_ sender: Any) {
        let dialog = Library.Import.dialogue(allowedFiles: Library.FileTypes.all)
        
        // TODO Allow only audiovisual files, and m3u
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            self.import(urls: dialog.urls)
        }
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        self.import(urls: urls)
    }
    
    func `import`(urls: [URL]) {
        if persistentContainer == nil, let url = urls.onlyElement, url.pathExtension == "ttl" {
            chooseLibrary(url)
            return
        }
        
        if persistentContainer == nil {
            // Will be called via openFiles before didFinishLaunching
            chooseLibrary()
        }
        
        let objects = urls.compactMap { Library.shared.import().guess(url: $0) }
        
        try! Library.shared.viewContext.save()
        
        if AppDelegate.defaults.consume(toggle: "fileImportTutorial") {
            NSAlert.tutorial(topic: "Importing Tracks", text: "When adding tracks to your library, the files will automatically be copied to your media directory. You can change this behavior in the preferences.")
        }
        
        let tracks = objects.compactMap { $0 as? Track }
        if tracks.count > 0, AppDelegate.defaults[.playOpenedFiles] {
            ViewController.shared.player.enqueue(tracks: tracks, at: .end)
            ViewController.shared.player.play(moved: 1)
        }
    }
}
