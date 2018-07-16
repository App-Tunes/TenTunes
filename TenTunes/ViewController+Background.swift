
//
//  ViewController+Background.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 25.02.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import AudioKit

extension ViewController {    
    func endTask() {
        self._workerSemaphore.signal()
    }
    
    func startBackgroundTasks() {
        self.visualTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true ) { [unowned self] (timer) in
            guard self.view.window?.isVisible ?? false else {
                return
            }
            
            self._waveformView.setBy(player: self.player.player)
            
            if !self._timePlayed.isHidden, !self._timeLeft.isHidden {
                self._timePlayed.stringValue = Int(self.player.player.currentTime).timeString
                self._timeLeft.stringValue = Int(self.player.player.duration - self.player.player.currentTime).timeString
            }
        }
        
        self.backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 10.0, repeats: true ) { [unowned self] (timer) in
            var taskers = PriorityQueue(ascending: true, startingValues: self.taskers)
            taskers.push(self.tasker)
            var haveWorkerKey = false
            
            while let tasker = taskers.pop(), let promise = tasker.promise {
                // Have a tasker that promises some task
                
                // If no worker key acquired yet, acquire one now
                haveWorkerKey = haveWorkerKey || self._workerSemaphore.acquireNow()
                if haveWorkerKey || promise <= 0 {
                    // We want a new task!
                    if let task = tasker.spawn() {
                        // TODO Might have changed the view!
                        self.runningTasks.append(task)
                        self.taskViewController._tableView?.reloadData()

                        // Task delivar'd, execute!
                        task.completion = { [unowned self, haveWorkerKey] in
                            if haveWorkerKey {
                                self._workerSemaphore.signal()
                            }
                            
                            self.runningTasks.remove(element: task)
                        }
                        task.execute()
                        haveWorkerKey = false
                        
                        if tasker.promise != nil {
                            // Tasker promises a new task, push back onto queue
                            taskers.push(tasker)
                        }
                    }
                    // Else the task has not delivar'd
                    // continue with popping the next tasker
                }
                else {
                    // No worker keys left and task doesn't warrant spawning a new one
                    break
                }
            }
            
            if haveWorkerKey {
                // Looks like we prematurely grabbed a key, give back
                self._workerSemaphore.signal()
            }
            
            // TODO Schedule timer that pushes export onto the task queue
            // TODO Fetch one metadata
        }
        
        // Requests are freaking slow with many tracks so do it rarely
        Timer.scheduledAsyncBlock(withTimeInterval: 10, repeats: true) {
            Library.shared.performChildBackgroundTask { mox in
                let request: NSFetchRequest = Track.fetchRequest()
                request.predicate = NSPredicate(format: "metadataFetched == false")
//                self.metadataToDo = Library.shared.viewContext.convert(try! mox.fetch(request))
            }
        }
    }
}
