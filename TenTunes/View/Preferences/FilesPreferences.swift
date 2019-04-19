//
//  ExportsPreferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Preferences

import Defaults

extension Defaults.Keys {
    static let forceSimpleFilePaths = Key<Bool>("forceSimpleFilePaths", default: true)

    static let skipExportITunes = Key<Bool>("skipExportITunes", default: false)
    static let skipExportM3U = Key<Bool>("skipExportM3U", default: false)
    static let skipExportAlias = Key<Bool>("skipExportAlias", default: false)
}

class FilesPreferences: NSViewController, Preferenceable {
    var toolbarItemTitle: String = "Files"
    var toolbarItemIcon: NSImage = NSImage(named: NSImage.Name.folderSmartName)!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
}
