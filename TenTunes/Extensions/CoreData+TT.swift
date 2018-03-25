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
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
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
}

extension NSManagedObject {
    func refresh(merge: Bool = false) {
        managedObjectContext!.refresh(self, mergeChanges: false)
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
