//
//  NSTableView+Header.swift
//  TenTunes
//
//  Created by Lukas Tenbrink on 23.11.18.
//  Copyright © 2018 ivorius. All rights reserved.
//

import Cocoa

extension NSTableView {
    class HiddenManager : NSObject, NSMenuDelegate {
        let tableView: NSTableView
        let defaultsKey: String
        
        var ignore: [String]
        
        var observerToken: NSKeyValueObservation?
        
        var defaults: [String: Bool] {
            get { return (UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String : Bool]) ?? [:] }
            set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
        }

        init(tableView: NSTableView, defaultsKey: String, ignore: [String]) {
            self.tableView = tableView
            self.defaultsKey = defaultsKey
            self.ignore = ignore
        }
        
        func start() {
            tableView.headerView!.menu = NSMenu()
            tableView.headerView!.menu!.delegate = self
            
            observerToken = UserDefaults.standard.observe(\.trackColumnsHidden, options: [.initial, .new]) { _, _ in
                self.updateMenu()
            }
        }
        
        func updateMenu() {
            // might have been removed in the meantime
            let menu = tableView.headerView?.menu
            
            menu?.removeAllItems()

            for column in tableView.tableColumns {
                guard !ignore.contains(column.identifier.rawValue) else {
                    continue
                }
                
                let item = NSMenuItem(title: column.headerCell.stringValue, action: #selector(columnItemClicked(_:)), keyEquivalent: "")
                item.target = self
                
                column.isHidden = defaults[column.identifier.rawValue] ?? false
                item.state = column.isHidden ? .off : .on
                item.representedObject = column
                
                menu?.addItem(item)
            }
        }
        
        @IBAction func columnItemClicked(_ sender: Any) {
            let item = sender as! NSMenuItem
            let column = item.representedObject as! NSTableColumn
            
            let hide = !column.isHidden
            
            column.isHidden = hide
            item.state = hide ? .off : .on
            
            defaults[column.identifier.rawValue] = hide
            tableView.sizeToFit()
        }
        
        func menuWillOpen(_ menu: NSMenu) {
            for item in menu.items {
                item.state = (item.representedObject as! NSTableColumn).isHidden ? .off : .on
            }
        }
    }
}
