//
//  Task.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class Tasker {
    var promise: Float? {
        return nil
    }
    
    func spawn(running: [Task]) -> Task? {
        return nil
    }
}

extension Tasker : Comparable {
    static func < (lhs: Tasker, rhs: Tasker) -> Bool {
        return lhs.promise ?? 10000000 < rhs.promise ?? 10000000
    }
    
    static func == (lhs: Tasker, rhs: Tasker) -> Bool {
        return false
    }
}

class QueueTasker : Tasker {
    var queue: PriorityQueue<Task> = PriorityQueue(ascending: true)
    
    override var promise: Float? {
        return queue.peek()?.priority
    }
    
    override func spawn(running: [Task]) -> Task? {
        return queue.pop()
    }
    
    func enqueue(task: Task) {
        if !queue.contains(task) {
            queue.push(task)
        }
        // Else TODO? Else we never call finish which might be bad
    }
    
    @discardableResult
    func replace(task: Task) -> Bool {
        for other in queue where other == task {
            if other.cancel() {
                enqueue(task: task)
                return true
            }
            else {
                return false
            }
        }
        
        enqueue(task: task)
        return true
    }
}

class Task {
    let manageSemaphore = DispatchSemaphore(value: 1)
    
    var completion: (() -> Swift.Void)?
    var finished = false
    
    var cancelled = false
    var cancelable = true
    
    init(priority: Float = 1) {
        self.priority = priority
    }
    
    // Priority <= 0 = Immediately spawn a new worker thread for this
    var priority: Float = 1
    
    var title: String { return "Unnamed Task" }
    
    var preventsQuit: Bool { return !cancelable }
    
    func execute() {
        
    }
    
    func performChildBackgroundTask(for library: Library, block: @escaping (NSManagedObjectContext) -> Void) {
        manageSemaphore.wait()
        
        guard !cancelled else {
            finish()
            manageSemaphore.signal()
            return
        }
        
        library.performChildBackgroundTask { context in
            self.manageSemaphore.signal()
            block(context)
        }
    }
    
    func checkCanceled() -> Bool {
        if cancelled {
            if !finished {
                finish()
            }
            return true
        }
        
        return false
    }
    
    func uncancelable() -> Bool {
        manageSemaphore.wait()
        cancelable = false
        manageSemaphore.signal()
        
        return checkCanceled()
    }
    
    @discardableResult
    func cancel() -> Bool {
        manageSemaphore.wait()
        
        guard cancelable else {
            manageSemaphore.signal()
            return false
        }
        
        cancelled = true
        
        manageSemaphore.signal()
        return true
    }
    
    func finish() {
        guard !finished else {
            fatalError("Finishing finished task!")
        }
        
        finished = true
        completion?()
    }
    
    func eq(other: Task) -> Bool {
        return other === self
    }
}

extension Task : Comparable {
    static func < (lhs: Task, rhs: Task) -> Bool {
        return lhs.priority < rhs.priority
    }
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        if lhs === rhs {
            return true
        }
        
        return type(of: lhs) == type(of: rhs) && lhs.eq(other: rhs)
    }
}

