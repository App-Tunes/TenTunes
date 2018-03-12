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
}
