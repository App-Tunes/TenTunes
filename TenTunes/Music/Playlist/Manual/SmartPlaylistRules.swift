//
//  SmartPlaylistRules.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 19.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

@objc public class SmartPlaylistRules : NSObject, NSCoding {
    let tokens: [SmartPlaylistRules.Token]
    let mode: Mode
    
    static var trivial: (Track) -> Bool {
        return { _ in true }
    }
    
    func filter(in context: NSManagedObjectContext, rguard: RecursionGuard<Playlist>? = nil) -> ((Track) -> Bool)? {
        guard !tokens.isEmpty || mode == .any else {
            return nil
        }
        
        let rguard = rguard ?? RecursionGuard()
        
        let filters = tokens.map { $0.filter(in: context, rguard: rguard) }
        let satisfier = mode == .any ? filters.anySatisfy : filters.allSatisfy
        
        return { track in
            // Try is because satisfier blindly rethrows
            return try! satisfier { $0(track) }
        }
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(tokens, forKey: "labels")
        aCoder.encode(mode == .any, forKey: "modeAny")
    }

    public required init?(coder aDecoder: NSCoder) {
        tokens = (aDecoder.decodeObject(forKey: "labels") as? [SmartPlaylistRules.Token?])?.compactMap { $0 } ?? []
        mode = aDecoder.decodeBool(forKey: "modeAny") ? .any : .all
    }
    
    init(tokens: [SmartPlaylistRules.Token] = [], mode: Mode = .all) {
        self.tokens = tokens
        self.mode = mode
    }
    
    public override var description: String {
        return "[\((tokens.map { $0.representation() }).joined(separator: mode == .any ? " | " : ", "))]"
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? SmartPlaylistRules else {
            return false
        }
        
        return tokens == object.tokens && mode == object.mode
    }
    
    enum Mode : String, Codable {
        case any, all
        
        var title: String {
            switch self {
            case .all:
                return "All"
            case .any:
                return "Any"
            }
        }
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
        
        var icons : String {
            // TODO Use red background instead when possible
            return (not ? "🚫" : "")
        }
        
        func representation(in context: NSManagedObjectContext? = nil) -> String {
            return ""
        }
        
        func inverted() -> SmartPlaylistRules.Token {
            let copy = NSKeyedArchiver.clone(self)!
            copy._not = !_not
            return copy
        }
        
        var data : Data { return NSKeyedArchiver.archivedData(withRootObject: self) }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let object = object as? SmartPlaylistRules.Token else {
                return false
            }
            return data == object.data
        }
    }
}

