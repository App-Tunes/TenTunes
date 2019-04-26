//
//  AppDelegate+Welcome.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 26.04.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa

extension AppDelegate {
    func wantedWelcomeSteps() -> [NSViewController] {
        #if DEBUG_WELCOME
        let force: Bool? = true
        #else
        let force: Bool? = AppDelegate.isTest ? false : nil
        #endif
        
        var steps: [NSViewController] = []
        
        let isFirstLaunch = AppDelegate.defaults.consume(toggle: "WelcomeWindow")
        if force ?? isFirstLaunch {
            if steps.isEmpty {
                steps += [
                    ConfirmStep.create(
                        text: "Ten Tunes says hi!",
                        buttonText: "Hi!!"
                    ),
                    ConfirmStep.create(
                        text: "You can begin listening shortly!\nBut let's get a few things sorted first.",
                        buttonText: "Uh... ok."
                    )
                ]
            }

            steps += [
                OptionsStep.create(text: "What best describes me is...", options: [
                    .create(text: "Music Listener", image: NSImage(named: .musicName)!) {
                        return true
                    },
                    .create(text: "DJ", image: NSImage(named: .albumName)!) {
                        #if !DEBUG_WELCOME
                        AppDelegate.switchToDJ()
                        #endif
                        return true
                    },
                ])
            ]
        }
        
        // Not guaranteed to be new, but really
        // If the user has made neither playlists nor imported tracks
        // They probably want this screen anyway
        let isNewLibrary = persistentContainer![PlaylistRole.playlists].children.count == 0 &&
            persistentContainer![PlaylistRole.library].tracksList.count == 0
        
        if force ?? isNewLibrary {
            steps.append(
                ConfirmStep.create(
                    text: "Let's get your new library set up.",
                    buttonText: "Okay dude"
                )
            )

            steps += [
                OptionsStep.create(text: "So where do we start?", options: [
                    .create(text: "Import iTunes Library", image: NSImage(named: .iTunesName)!) { [unowned self] in
                        return self.importFromITunes(flat: true)
                    },
                    .create(text: "Import Music Folder", image: NSImage(named: .musicName)!, action: nil),
                    .create(text: "Start Fresh", image: NSImage(named: .nameName)!) {
                        return true
                    },
                ])
            ]
        }
        
        if !steps.isEmpty {
            if isNewLibrary {
                steps.append(
                    ConfirmStep.create(
                        text: "And that's it!\nHave fun with Ten Tunes!",
                        buttonText: "Let's Go!",
                        mode: .complete
                    ) { [unowned self] in
                        self.commenceAfterWelcome()
                    }
                )
            }
            else {
                steps.append(
                    ConfirmStep.create(
                        text: "Alright, that's it. Have fun!",
                        buttonText: "Sure, thanks!",
                        mode: .complete
                    ) { [unowned self] in
                        self.commenceAfterWelcome()
                    }
                )
            }
        }
        
        return steps
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

    func commenceAfterWelcome() {
        // Initially check on every launch
        Library.shared.checkSanity()
        
        #if !DEBUG
        SuperpoweredSplash.show(in: (libraryWindowController.contentViewController as! ViewController)._trackGuardView.superview!.superview!)
        #endif
        
        libraryWindowController.window!.makeKeyAndOrderFront(self)
    }
}
