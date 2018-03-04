//
//  Track+CoreDataClass.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 03.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Track)
public class Track: NSManagedObject {
    var analysis: Analysis?
    
    func readAnalysis() -> Bool {
        if let analysisData = analysisData {
            if let decoded = NSKeyedUnarchiver.unarchiveObject(with: analysisData as Data) as? Analysis {
                if let analysis = analysis {
                    analysis.set(from: decoded)
                }
                else {
                    analysis = decoded
                }
                return true
            }
        }
        
        return false
    }
    
    func writeAnalysis() {
        analysisData = NSKeyedArchiver.archivedData(withRootObject: analysis!) as NSData
    }
    
    var artwork: NSImage?
    var artworkPreview: NSImage?
}
