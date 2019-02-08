//
//  ExportsPreferences.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 08.02.19.
//  Copyright © 2019 ivorius. All rights reserved.
//

import Cocoa
import Preferences

extension UserDefaults {
    var skipExportITunes: Bool {
        return bool(forKey: "skipExportITunes")
    }
    
    var skipExportM3U: Bool {
        return bool(forKey: "skipExportM3U")
    }
    
    var skipExportAlias: Bool {
        return bool(forKey: "skipExportAlias")
    }
}

class ExportsPreferences: NSViewController, Preferenceable {
    var toolbarItemTitle: String = "Exports"
    var toolbarItemIcon: NSImage = NSImage(named: .folderSmart)!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
}
