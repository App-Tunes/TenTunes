//
//  Label.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc public class PlaylistRules : NSObject, NSCoding {
    var labels: [TrackLabel]
    
    func filter(in context: NSManagedObjectContext) -> ((Track) -> Bool) {
        let filters = labels.map { $0.filter(in: context) }
        return { track in
            return filters.allMatch { $0(track) }
        }
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(labels, forKey: "labels")
    }

    public required init?(coder aDecoder: NSCoder) {
        labels = (aDecoder.decodeObject(forKey: "labels") as? [TrackLabel?])?.compactMap { $0 } ?? []
    }
    
    init(labels: [TrackLabel] = []) {
        self.labels = labels
    }
    
    public override var description: String {
        return "[\((labels.map { $0.representation() }).joined(separator: ", "))]"
    }
    
    public override var hashValue: Int {
        return (labels.map { $0.representation() }).reduce(0, { (hash, string) in
            hash ^ string.hash
        })
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? PlaylistRules else {
            return false
        }
        
        return labels == object.labels
    }
}

@objc class TrackLabel : NSObject, NSCoding {
    var not = false
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(not, forKey: "not")
    }
    
    override init() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        not = aDecoder.decodeBool(forKey: "not")
    }
    
    func filter(in context: NSManagedObjectContext) -> (Track) -> Bool {
        let positive = positiveFilter(in: context)
        return not ? { !positive($0) } : positive
    }
    
    func positiveFilter(in context: NSManagedObjectContext) -> (Track) -> Bool {
        return { _ in return false }
    }
    
    func representation(in context: NSManagedObjectContext? = nil) -> String {
        // TODO Use red background instead when possible
        return (not ? "🚫 " : "") + positiveRepresentation(in: context)
    }

    func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String { return "" }
    
    var data : NSData { return NSKeyedArchiver.archivedData(withRootObject: self) as NSData }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TrackLabel else {
            return false
        }
        return data == object.data
    }
}

