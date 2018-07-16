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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension TaskViewController : NSTableViewDelegate {
    
}

extension TaskViewController : NSTableViewDataSource {
    fileprivate enum CellIdentifiers {
        static let title = NSUserInterfaceItemIdentifier(rawValue: "titleCell")
    }
    
    fileprivate enum ColumnIdentifiers {
        static let title = NSUserInterfaceItemIdentifier(rawValue: "titleColumn")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        // TODO What we working on right now?
        return tasker.queue.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier == ColumnIdentifiers.title, let view = tableView.makeView(withIdentifier: CellIdentifiers.title, owner: nil) as? NSTableCellView {
            view.textField?.stringValue = tasker.queue[row].title
            return view
        }
        
        return nil
    }
}
