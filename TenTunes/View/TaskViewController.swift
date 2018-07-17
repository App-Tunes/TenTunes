//
//  TaskViewController.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 16.07.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

class TaskViewController: NSViewController {
    
    @IBOutlet var _tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    fileprivate class TaskGroup {
        var running = false
        var title = ""
        var count = 1
        
        init(title: String, running: Bool) {
            self.title = title
            self.running = running
        }
    }
    
    fileprivate var taskGroups: [TaskGroup] = []
    
    func reload(force: Bool = false) {
        guard force || view.visibleRect != NSZeroRect else {
            return
        }
        
        var dict: [String: TaskGroup] = [:]
        
        for task in ViewController.shared.runningTasks {
            if let group = dict[task.title] {
                group.count += 1
            }
            else {
                dict[task.title] = TaskGroup(title: task.title, running: true)
            }
        }
        
        for task in ViewController.shared.tasker.queue {
            if let group = dict[task.title] {
                group.count += 1
            }
            else {
                dict[task.title] = TaskGroup(title: task.title, running: false)
            }
        }
        
        taskGroups = Array(dict.values)
        _tableView?.reloadData()
    }
}

extension TaskViewController : NSTableViewDelegate {
    
}

extension TaskViewController : NSTableViewDataSource {
    fileprivate enum CellIdentifiers {
        static let title = NSUserInterfaceItemIdentifier(rawValue: "titleCell")
        static let busy = NSUserInterfaceItemIdentifier(rawValue: "busyCell")
    }
    
    fileprivate enum ColumnIdentifiers {
        static let title = NSUserInterfaceItemIdentifier(rawValue: "titleColumn")
        static let busy = NSUserInterfaceItemIdentifier(rawValue: "busyColumn")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return taskGroups.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let taskGroup = taskGroups[safe: row] else {
            return nil
        }
        
        if tableColumn?.identifier == ColumnIdentifiers.title, let view = tableView.makeView(withIdentifier: CellIdentifiers.title, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = taskGroup.count > 1 ? "(\(taskGroup.count)) \(taskGroup.title)" : taskGroup.title
            return view
        }

        if taskGroup.running {
            if tableColumn?.identifier == ColumnIdentifiers.busy, let view = tableView.makeView(withIdentifier: CellIdentifiers.busy, owner: nil) as? NSProgressIndicator {
                view.startAnimation(self)
                return view
            }
        }

        return nil
    }
}

