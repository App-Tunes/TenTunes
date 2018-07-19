//
//  CoreData+TT.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 09.03.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import CoreData

extension NSPersistentContainer {
    func newConcurrentContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = viewContext
        return context
    }

    func newChildBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = viewContext
        return context
    }
    
    func performChildBackgroundTask(_ task: @escaping (NSManagedObjectContext) -> Swift.Void) {
        let context = newChildBackgroundContext()
        context.perform {
            task(context)
        }
    }
    
    var defaultMetadata : [String : Any] {
        get { return persistentStoreCoordinator.metadata(for: persistentStoreCoordinator.persistentStores[0]) }
        set { return persistentStoreCoordinator.setMetadata(newValue, for: persistentStoreCoordinator.persistentStores[0]) }
    }
}

extension NSManagedObject {
    func refresh(merge: Bool = false) {
        managedObjectContext!.refresh(self, mergeChanges: false)
    }
    
    static func markDirty<C, T>(_ obj: C, _ keyPath: ReferenceWritableKeyPath<C, T>) {
        obj[keyPath: keyPath] = obj[keyPath: keyPath]
    }
    
    func duplicate(only: [String]) -> NSManagedObject {
        return duplicate { only.contains($0) ? .copy : .none }
    }
    
    func duplicate(except: [String], deep: [String] = []) -> NSManagedObject {
        return duplicate { deep.contains($0) ? .deepcopy : except.contains($0) ? .none : .copy }
    }
    
    enum CopyBehavior {
        case none, copy, deepcopy
    }

    func duplicate(byProperties fun: (String) -> CopyBehavior) -> NSManagedObject {
        let duplicate = NSEntityDescription.insertNewObject(forEntityName: entity.name!, into: managedObjectContext!)
        
        for propertyName in entity.propertiesByName.keys {
            switch fun(propertyName) {
            case .copy:
                let value = self.value(forKey: propertyName)
                duplicate.setValue(value, forKey: propertyName)
            case .deepcopy:
                let value = self.value(forKey: propertyName)
                if let value = value as? NSSet {
                    let copy = value.map {
                        return ($0 as! NSManagedObject).duplicate(byProperties: fun)
                    }
                    duplicate.setValue(copy, forKey: propertyName)
                }
                else if let value = value as? NSOrderedSet {
                    let copy = value.map {
                        return ($0 as! NSManagedObject).duplicate(byProperties: fun)
                    }
                    duplicate.setValue(NSOrderedSet(array: copy), forKey: propertyName)
                }
                else if let value = value as? NSManagedObject {
                    let copy = value.duplicate(byProperties: fun)
                    duplicate.setValue(copy, forKey: propertyName)
                }
                else {
                    fatalError("Unrecognized thing to copy")
                }
            case .none:
                break
            }
        }
        
        return duplicate
    }
}

extension NSManagedObjectContext {
    public func convert<T : NSManagedObject>(_ t: T) -> T {
        return object(with: t.objectID) as! T
    }

    public func convert<T : NSManagedObject>(_ ts: [T]) -> [T] {
        // TODO If many, fetch all at once
        return ts.map(convert)
    }
    
    public func delete(all: [NSManagedObject]) {
        for object in all {
            delete(object)
        }
    }
}
