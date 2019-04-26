//
//  AppDelegate+Welcome.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension AppDelegate {
    func chooseLibrary(create: Bool) -> Bool {
        var location: URL?
        
        if create {
            let dialog = NSSavePanel()
            location = dialog.runModal() == .OK ? dialog.url : nil
        }
        else {
            let dialog = NSOpenPanel()
            
            dialog.canChooseFiles = true // packages are considered files by finder, library is a package
            dialog.canChooseDirectories = true
            dialog.allowedFileTypes = ["de.ivorius.tentunes.library"]
            dialog.directoryURL = location
            
            location = dialog.runModal() == .OK ? dialog.url : nil
        }
        
        // TODO Allow overrides (the save dialogue specifically prompts for it)
        return location.map { tryLibrary(at: $0, create: create) } ?? false
    }
    
    func addLibraryWelcomeSteps(workflow: WorkflowWindowController, isFirstLaunch: Bool, force: Bool?) {
        let isNewLibrary =
            persistentContainer![PlaylistRole.playlists].children.count == 0 &&
            persistentContainer![PlaylistRole.library].tracksList.count == 0
        
        if force ?? isNewLibrary {
            workflow.addStep(
                .interaction(ConfirmStep.create(
                    text: "Let's get your new library set up.",
                    buttonText: "Sure"
                ))
            )
            
            workflow.addSteps([
                .interaction(OptionsStep.create(text: "So where do we start?", options: [
                    .create(text: "Import iTunes Library", image: NSImage(named: .iTunesName)!) { [unowned self] in
                        return self.importFromITunes(flat: true)
                    },
                    .create(text: "Import Music Folder", image: NSImage(named: .musicName)!, action: nil),
                    .create(text: "Start Fresh", image: NSImage(named: .nameName)!) {
                        return true
                    },
                ]))
            ])
        }
        
        // Not guaranteed to be new, but really
        // If the user has made neither playlists nor imported tracks
        // They probably want this screen anyway
        
        if !workflow.isEmpty {
            if isFirstLaunch {
                workflow.addStep(
                    .interaction(ConfirmStep.create(
                        text: "And that's it!\nHave fun with Ten Tunes!",
                        buttonText: "Let's Go!",
                        mode: .complete
                    ) { [unowned self] in
                        self.commenceAfterWelcome()
                    })
                )
            }
            else {
                workflow.addStep(
                    .interaction(ConfirmStep.create(
                        text: "Alright, that's it. Have fun!",
                        buttonText: "Cool, thanks!",
                        mode: .complete
                    ) { [unowned self] in
                        self.commenceAfterWelcome()
                    })
                )
            }
        }
    }
    
    func addWelcomeSteps(workflow: WorkflowWindowController, chooseLibrary: Bool) {        
        #if DEBUG_WELCOME
        let force: Bool? = true
        #else
        let force: Bool? = AppDelegate.isTest ? false : nil
        #endif
        
        let isFirstLaunch = AppDelegate.defaults.consume(toggle: "WelcomeWindow")
        if force ?? isFirstLaunch {
            if workflow.isEmpty {
                workflow.addSteps([
                    .interaction(ConfirmStep.create(
                        text: "Ten Tunes says hi!",
                        buttonText: "Hi!!"
                    )),
                    .interaction(ConfirmStep.create(
                        text: "You can begin listening shortly!\nBut let's get a few things sorted first.",
                        buttonText: "Uh... ok."
                    )),
                    .interaction(OptionsStep.create(text: "What best describes you is...", options: [
                        .create(text: "Music Listener", image: NSImage(named: .musicName)!) {
                            return true
                        },
                        .create(text: "DJ", image: NSImage(named: .albumName)!) {
                            #if !DEBUG_WELCOME
                            AppDelegate.switchToDJ()
                            #endif
                            return true
                        },
                    ]))
                ])
            }
        }
        
        if persistentContainer == nil {
            // Need to choose a library
            workflow.addSteps([
                .interaction(OptionsStep.create(text: "We need a library location\nto store your music.", options: [
                    .create(text: "Use Existing", image: NSImage(named: .folderName)!) { [unowned self] in
                        return self.chooseLibrary(create: false)
                    },
                    .create(text: "Create New", image: NSImage(named: .repeatName)!) { [unowned self] in
                        return self.chooseLibrary(create: true)
                    },
                ])),
                .task { [unowned self] in
                    self.addLibraryWelcomeSteps(workflow: workflow, isFirstLaunch: isFirstLaunch, force: force)
                }
            ])
        }
        else {
            // Have a library, but still might be empty
            addLibraryWelcomeSteps(workflow: workflow, isFirstLaunch: isFirstLaunch, force: force)
        }
    }
    
    static func switchToDJ() {
        AppDelegate.defaults[.trackWordSingular] = "track"
        AppDelegate.defaults[.trackWordPlural] = "tracks"
        AppDelegate.defaults[.keepFilterBetweenPlaylists] = true
        AppDelegate.defaults[.quantizedJump] = true
        AppDelegate.defaults[.initialKeyWrite] = .openKey
        AppDelegate.defaults[.trackColumnsHidden] = [
            "albumColumn": true,
            "authorColumn": true,
        ]
    }
}
