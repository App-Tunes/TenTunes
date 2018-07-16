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
    
    var taskers: [Tasker] {
        return ViewController.shared.taskers
    }
    
    var tasker: QueueTasker {
        return ViewController.shared.tasker
    }

    var runningTasks: [Task] {
        return ViewController.shared.runningTasks
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
        return runningTasks.count + tasker.queue.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let task = runningTasks[safe: row] ?? tasker.queue[safe: row - runningTasks.count] else {
            return nil
        }
        
        if tableColumn?.identifier == ColumnIdentifiers.title, let view = tableView.makeView(withIdentifier: CellIdentifiers.title, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = task.title
            return view
        }

        if row < runningTasks.count {
            if tableColumn?.identifier == ColumnIdentifiers.busy, let view = tableView.makeView(withIdentifier: CellIdentifiers.busy, owner: nil) as? NSProgressIndicator {
                view.startAnimation(self)
                return view
            }
        }

        return nil
    }
}

