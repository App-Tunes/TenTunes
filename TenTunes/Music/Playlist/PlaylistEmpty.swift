//
//  PlaylistEmpty.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.04.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Foundation

class PlaylistEmpty : PlaylistProtocol {
    var name: String {
        return ""
    }
    
    var tracksList: [Track] {
        return []
    }
    
    func convert(to: NSManagedObjectContext) -> Self {
        return self
    }
}
