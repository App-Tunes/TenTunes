//
//  NSTableView+Header.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa
import Defaults

extension NSTableView {
    static let columnDidChangeVisibilityNotification = NSNotification.Name("NSTableViewColumnDidChangeVisibilityNotification")

    class ActiveSynchronizer {
        let tableView: NSTableView
        
        var moveObserver: NSObjectProtocol?
        var resizeObserver: NSObjectProtocol?
        var visibleObserver: NSObjectProtocol?

        var key: NSTableView.AutosaveName? {
            tableView.autosaveName
        }
        
        init(tableView: NSTableView) {
            self.tableView = tableView
        }
        
        func attach() {
            moveObserver = NotificationCenter.default.addObserver(forName: NSTableView.columnDidMoveNotification, object: nil, queue: .main) { [unowned self] notification in
                let tableView = notification.object as! NSTableView

                guard tableView != self.tableView, tableView.autosaveName == self.tableView.autosaveName else {
                    return
                }
                
                let oldIndex = notification.userInfo!["NSOldColumn"] as! Int
                let newIndex = notification.userInfo!["NSNewColumn"] as! Int
                let column = tableView.tableColumns[newIndex]

                guard self.tableView.column(withIdentifier: column.identifier) == oldIndex else {
                    return
                }
                
                self.tableView.moveColumn(oldIndex, toColumn: newIndex)
            }

            resizeObserver = NotificationCenter.default.addObserver(forName: NSTableView.columnDidResizeNotification, object: nil, queue: .main) { [unowned self] notification in
                let tableView = notification.object as! NSTableView
                
                guard tableView != self.tableView, tableView.autosaveName == self.tableView.autosaveName else {
                    return
                }

                let column = notification.userInfo!["NSTableColumn"] as! NSTableColumn
                let selfColumn = self.tableView.tableColumn(withIdentifier: column.identifier)!
                
                if selfColumn.width != column.width {
                    selfColumn.width = column.width
                }
            }

            visibleObserver = NotificationCenter.default.addObserver(forName: NSTableView.columnDidChangeVisibilityNotification, object: nil, queue: .main) { [unowned self] notification in
                let tableView = notification.object as! NSTableView
                
                guard tableView != self.tableView, tableView.autosaveName == self.tableView.autosaveName else {
                    return
                }

                let column = notification.userInfo!["NSTableColumn"] as! NSTableColumn
                let selfColumn = self.tableView.tableColumn(withIdentifier: column.identifier)!
                
                if selfColumn.isHidden != column.isHidden {
                    selfColumn.isHidden = column.isHidden
                }
            }
        }
    }
    
    class ColumnHiddenExtension : NSObject, NSMenuDelegate {
        let tableView: NSTableView
        var titles: [NSUserInterfaceItemIdentifier: String] = [:]
        var affix: Set<String>
        
        init(tableView: NSTableView, titles: [NSUserInterfaceItemIdentifier: String] = [:], affix: Set<String> = Set()) {
            self.tableView = tableView
            self.titles = titles
            self.affix = affix
        }
        
        func attach() {
            tableView.headerView!.menu = NSMenu()
            tableView.headerView!.menu!.delegate = self
            
            updateMenu()
        }
        
        func updateMenu() {
            // might have been removed in the meantime
            guard let menu = tableView.headerView?.menu else {
                return
            }
            
            menu.removeAllItems()

            for column in tableView.tableColumns {
                guard !affix.contains(column.identifier.rawValue) else {
                    continue
                }
                
                let item = NSMenuItem(title: titles[column.identifier] ?? column.headerCell.stringValue, action: #selector(columnItemClicked(_:)), keyEquivalent: "")
                item.target = self
                
                item.state = column.isHidden ? .off : .on
                item.representedObject = column
                
                menu.addItem(item)
            }
        }
        
        func menuWillOpen(_ menu: NSMenu) {
            for item in menu.items {
                item.state = (item.representedObject as! NSTableColumn).isHidden ? .off : .on
            }
        }

        @IBAction func columnItemClicked(_ sender: Any) {
            let item = sender as! NSMenuItem
            let column = item.representedObject as! NSTableColumn
            
            let hide = !column.isHidden
            
            column.isHidden = hide
            item.state = hide ? .off : .on
            NotificationCenter.default.post(name: columnDidChangeVisibilityNotification, object: tableView, userInfo: ["NSTableColumn": column])

            tableView.sizeToFit()
        }
    }
}
