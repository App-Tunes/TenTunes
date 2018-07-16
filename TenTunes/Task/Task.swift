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
        queue.push(task)
    }
}

class Task {
    var completion: (() -> Swift.Void)?
    var finished = false
    
    // Priority <= 0 = Immediately spawn a new worker thread for this
    var priority: Float { return 1 }
    
    var title: String { return "Unnamed Task" }
    
    func execute() {
        
    }
    
    func finish() {
        guard !finished else {
            fatalError("Finishing finished task!")
        }
        
        finished = true
        completion?()
    }
}

extension Task : Comparable {
    static func < (lhs: Task, rhs: Task) -> Bool {
        return lhs.priority < rhs.priority
    }
    
    // TODO Implement this
    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs === rhs
    }
}
