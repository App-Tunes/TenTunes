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
        
        let isFirstLaunch = force ?? AppDelegate.defaults.consume(toggle: "WelcomeWindow")
        let firstLaunchSteps = isFirstLaunch ? [
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
        ] : []
        
        // Not guaranteed to be new, but really
        // If the user has made neither playlists nor imported tracks
        // They probably want this screen anyway
        let isNewLibrary = force ?? (
            persistentContainer![PlaylistRole.playlists].children.count == 0 &&
                persistentContainer![PlaylistRole.library].tracksList.count == 0
        )
        let newLibrarySteps = isNewLibrary ? [
            OptionsStep.create(text: "So where do we start?", options: [
                .create(text: "Import iTunes Library", image: NSImage(named: .iTunesName)!) { [unowned self] in 
                    return self.importFromITunes(flat: true)
                },
                .create(text: "Import Music Folder", image: NSImage(named: .musicName)!, action: nil),
                .create(text: "Start Fresh", image: NSImage(named: .nameName)!) {
                    return true
                },
            ])
        ] : []
        
        return firstLaunchSteps + newLibrarySteps
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
