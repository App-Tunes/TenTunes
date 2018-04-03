//
//  PlaylistProtocol.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 04.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

protocol PlaylistProtocol : class {
    var tracksList: [Track] { get }
    var name: String { get }
    
    func convert(to: NSManagedObjectContext) -> Self
}
