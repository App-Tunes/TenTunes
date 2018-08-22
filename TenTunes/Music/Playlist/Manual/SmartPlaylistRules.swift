//
//  Label.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc public class SmartPlaylistRules : NSObject, NSCoding {
    let labels: [SmartPlaylistRules.Token]
    let any: Bool
    
    func filter(in context: NSManagedObjectContext, rguard: RecursionGuard<Playlist>? = nil) -> ((Track) -> Bool) {
        let rguard = rguard ?? RecursionGuard()
        
        let filters = labels.map { $0.filter(in: context, rguard: rguard) }
        let any = self.any
        
        return { track in
            return (any ? filters.anyMatch : filters.allMatch) { $0(track) }
        }
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(labels, forKey: "labels")
        aCoder.encode(any, forKey: "modeAny")
    }

    public required init?(coder aDecoder: NSCoder) {
        labels = (aDecoder.decodeObject(forKey: "labels") as? [SmartPlaylistRules.Token?])?.compactMap { $0 } ?? []
        any = aDecoder.decodeBool(forKey: "modeAny")
    }
    
    init(labels: [SmartPlaylistRules.Token] = [], any: Bool = false) {
        self.labels = labels
        self.any = any
    }
    
    public override var description: String {
        return "[\((labels.map { $0.representation() }).joined(separator: any ? " | " : ", "))]"
    }
    
    public override var hashValue: Int {
        return (labels.map { $0.representation() }).reduce(0, { (hash, string) in
            hash ^ string.hash
        }) * (any ? -1 : 1)
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SmartPlaylistRules else {
            return false
        }
        
        return labels == object.labels && any == object.any
    }
    
    @objc(TenTunes_SmartPlaylistRules_Token) class Token : NSObject, NSCoding {
        var _not: Bool
        
        func encode(with aCoder: NSCoder) {
            aCoder.encode(not, forKey: "not")
        }
        
        init(not: Bool = false) {
            _not = not
        }
        
        required init?(coder aDecoder: NSCoder) {
            _not = aDecoder.decodeBool(forKey: "not")
        }
        
        var not: Bool { // So it's get-only, though for convenience the var itself is var, not let
            return _not
        }
        
        func filter(in context: NSManagedObjectContext, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            let positive = positiveFilter(in: context, rguard: rguard)
            return not ? { !positive($0) } : positive
        }
        
        func positiveFilter(in context: NSManagedObjectContext, rguard: RecursionGuard<Playlist>) -> (Track) -> Bool {
            return { _ in return false }
        }
        
        func representation(in context: NSManagedObjectContext? = nil) -> String {
            // TODO Use red background instead when possible
            return (not ? "🚫 " : "") + positiveRepresentation(in: context)
        }
        
        func inverted() -> SmartPlaylistRules.Token {
            let copy = NSKeyedUnarchiver.unarchiveObject(with: data) as! SmartPlaylistRules.Token
            copy._not = !_not
            return copy
        }
        
        func positiveRepresentation(in context: NSManagedObjectContext? = nil) -> String { return "" }
        
        var data : Data { return NSKeyedArchiver.archivedData(withRootObject: self) }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let object = object as? SmartPlaylistRules.Token else {
                return false
            }
            return data == object.data
        }
    }
}

