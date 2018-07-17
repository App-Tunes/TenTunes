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
    
    func spawn() -> Task? {
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
    
    override func spawn() -> Task? {
        return queue.pop()
    }
    
    func enqueue(task: Task) {
        if !queue.contains(task) {
            queue.push(task)
        }
        // Else TODO? Else we never call finish which might be bad
    }
}

class Task {
    var completion: (() -> Swift.Void)?
    var finished = false
    
    init(priority: Float = 1) {
        self.priority = priority
    }
    
    // Priority <= 0 = Immediately spawn a new worker thread for this
    var priority: Float = 1
    
    var title: String { return "Unnamed Task" }
    
    var preventsQuit: Bool { return true }
    
    func execute() {
        
    }
    
    func finish() {
        guard !finished else {
            fatalError("Finishing finished task!")
        }
        
        finished = true
        completion?()
    }
    
    func eq(other: Task) -> Bool {
        return true
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
